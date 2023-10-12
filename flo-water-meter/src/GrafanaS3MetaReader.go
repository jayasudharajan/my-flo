package main

import (
	"context"
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/sync/semaphore"

	"github.com/aws/aws-sdk-go/aws"
	aw "github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

// GrafanaS3MetaReader has logic for fetching s3 metadata objects. Code uses redis to cache
type GrafanaS3MetaReader struct {
	redis     *RedisConnection
	redisTTLS int //how long to store metadata in cache seconds

	S3Bucket   string   //bucket name
	S3V8Path   []string //csv+gz
	S3V7Path   string   //parquet+zippy
	awsSession *aw.Session
	s3Svc      *s3.S3 //s3 service meta info

	_ctx       context.Context
	_ctxCancel context.CancelFunc
	_semMeta   *semaphore.Weighted
}

func (g *GrafanaS3FileReader) CreateGrafanaS3MetaReader() *GrafanaS3MetaReader {
	if g == nil {
		return nil
	}
	r := GrafanaS3MetaReader{
		redis: g.redis,

		S3Bucket:   g.S3Bucket,
		S3V8Path:   g.S3V8Path,
		S3V7Path:   g.S3V7Path,
		awsSession: g.awsSession,
	}
	r._ctx, r._ctxCancel = context.WithCancel(context.Background())
	r._semMeta = semaphore.NewWeighted(60) //max concurrent S3 meta fetches, tested to be slower above or bellow this

	if g.redisPrivateCluster {
		r.redisTTLS = (365 + (4 * 31)) * int(SEC_IN_DAY)
	} else {
		r.redisTTLS = 64 * int(SEC_IN_DAY)
	}
	r.s3Svc = s3.New(g.awsSession) //used to get s3 meta data
	return &r
}

func (gs *GrafanaS3MetaReader) Close() {
	if gs == nil {
		return
	}
	gs._ctxCancel() //don't wait just kill
	return
}

type S3MetaObject struct {
	DtUnix  int64  `json:"dt,omitempty"`
	Etag    string `json:"et,omitempty"`
	Key     string `json:"k,omitempty"`
	Size    int64  `json:"sz,omitempty"`
	LastMod int64  `json:"up,omitempty"`
}

func (m *S3MetaObject) GetTime() time.Time {
	return time.Unix(m.DtUnix, 0).UTC()
}
func (m *S3MetaObject) SetTime(d time.Time) {
	m.DtUnix = d.UTC().Unix()
}
func (m *S3MetaObject) GetMeta() *s3.Object {
	o := s3.Object{
		ETag:         aws.String(m.Etag),
		Key:          aws.String(m.Key),
		Size:         aws.Int64(m.Size),
		LastModified: aws.Time(time.Unix(m.LastMod, 0).UTC()),
	}
	return &o
}
func (m *S3MetaObject) SetMeta(o *s3.Object) {
	if o == nil {
		return
	}
	m.Etag = strings.ReplaceAll(aws.StringValue(o.ETag), "\"", "")
	m.Key = aws.StringValue(o.Key)
	m.Size = aws.Int64Value(o.Size)
	m.LastMod = o.LastModified.UTC().Unix()
}

func (gs *GrafanaS3MetaReader) GetRange(deviceId string, start time.Time, end time.Time) []S3MetaObject {
	procStart := time.Now()
	dMap := gs.cacheFetch(deviceId, start, end) //check meta cache first

	ch := make(chan []S3MetaObject)
	defer close(ch)
	srcFetches := 0 //fire all the none blocking fetches
	cacheFound := 0
	for k, v := range dMap {
		if v != nil {
			cacheFound++
			continue
		}
		dt := k.UTC()
		srcFetches++
		go gs.metaScan(deviceId, dt, ch) //only pull meta from s3 when missing from cache
	}

	if srcFetches == 0 && cacheFound == 0 {
		logInfo("GrafanaS3MetaReader.GetRange: took %vms -> %v/%v buckets for %v %v - %v",
			time.Since(procStart).Milliseconds(), srcFetches+cacheFound, len(dMap), deviceId, start.Format(DT_FORMAT_XML), end.Format(DT_FORMAT_XML))
		return []S3MetaObject{} //found nothing new in s3
	}
	var mux sync.Mutex
	for srcFetches > 0 { //loop & wait for responses from s3
		arr := <-ch
		if arr == nil {
			srcFetches--
		} else if len(arr) > 0 {
			kk := arr[0].GetTime()

			mux.Lock()
			dMap[kk] = arr
			mux.Unlock()
		}
	}
	flatRes := gs.collapseSortResults(dMap)
	logInfo("GrafanaS3MetaReader.GetRange: took %vms -> %v/%v buckets for %v %v - %v",
		time.Since(procStart).Milliseconds(), len(flatRes), len(dMap), deviceId, start.Format(DT_FORMAT_XML), end.Format(DT_FORMAT_XML))
	return flatRes
}

func (gs *GrafanaS3MetaReader) collapseSortResults(dMap map[time.Time][]S3MetaObject) []S3MetaObject {
	mCount := 0 //cap array growth
	for _, mArr := range dMap {
		mCount += len(mArr)
	}
	metas := make([]S3MetaObject, mCount) //flatten results list
	ii := 0
	for _, mArr := range dMap {
		for _, m := range mArr {
			metas[ii] = m
			ii++
		}
	}
	sort.Slice(metas, func(i, j int) bool {
		return metas[i].DtUnix < metas[j].DtUnix //sort metas ascending by date
	})
	return metas
}

func (gs *GrafanaS3MetaReader) metaScan(deviceId string, when time.Time, resCh chan []S3MetaObject) {
	defer recoverPanic(_log, "metaScan: %v %v", deviceId, when)
	if gs == nil || resCh == nil {
		return
	}
	defer func(ch chan []S3MetaObject) { //ensure done signal
		if ch != nil {
			ch <- nil
		}
	}(resCh)

	var arr []S3MetaObject
	func() {
		gs._semMeta.Acquire(gs._ctx, 1) //ensure we don't go beyond concurrent limit
		defer gs._semMeta.Release(1)
		arr = gs.metaFetch(deviceId, when, gs.S3V8Path...)
	}()
	//if len(arr) == 0 { //NOTE: we are no longer supporting v7 telemetry period
	//	func() {
	//		gs._semMeta.Acquire(gs._ctx, 1) //ensure we don't go beyond concurrent limit
	//		defer gs._semMeta.Release(1)
	//		arr = gs.metaFetch(deviceId, when, gs.S3V7Path)
	//	}()
	//}
	if len(arr) > 0 && resCh != nil {
		resCh <- arr
	}
}

func (gs *GrafanaS3MetaReader) Ping() error {
	for _, p := range gs.S3V8Path {
		var (
			delimiter       = "/"
			maxKeys   int64 = 1
			s               = strings.ReplaceAll(p, "//", "/")
		)
		if s[0:1] == "/" {
			s = s[1:] //remove path starting string
		}
		p := &s3.ListObjectsInput{
			Bucket:    &gs.S3Bucket,
			Delimiter: &delimiter,
			Prefix:    &s,
			MaxKeys:   &maxKeys,
		}
		if _, e := gs.s3Svc.ListObjects(p); e != nil {
			return logError("S3 Ping -> %v", e)
		}
	}
	logTrace("S3 Ping")
	return nil
}

func (gs *GrafanaS3MetaReader) formatS3KeyPrefixForRange(rootPath string, shard string, deviceId string, when time.Time) string {
	s := fmt.Sprintf("%v/year=%v/month=%v/day=%v/hhmm=%v/deviceid=%v/",
		rootPath, when.Format("2006"), when.Format("01"), when.Format("02"), when.Format("1504"), deviceId)
	s = strings.Replace(s, ":shard", shard, -1)
	s = strings.ReplaceAll(s, "//", "/")
	if s[0:1] == "/" {
		s = s[1:] //remove path starting string
	}
	return s
}

//get the wildcard that will allow us to fetch the telemetry file for this time slot.
//NOTE: file name is not deterministic b/c of hash :. we have to rely on wildcard
func (gs *GrafanaS3MetaReader) metaFetch(deviceId string, when time.Time, rootPath ...string) []S3MetaObject {
	shard := deviceId[len(deviceId)-2:]
	for _, rp := range rootPath {
		s := gs.formatS3KeyPrefixForRange(rp, shard, deviceId, when)

		delimiter := "/"
		var maxKeys int64 = 10
		p := &s3.ListObjectsInput{
			Bucket:    &gs.S3Bucket,
			Delimiter: &delimiter,
			Prefix:    &s,
			MaxKeys:   &maxKeys,
		}
		//rqStart := time.Now()
		objs, e := gs.s3Svc.ListObjects(p)
		if e != nil {
			logError("GrafanaS3MetaReader.getKeys: %v", e.Error())
			return []S3MetaObject{}
		} else {
			//logTrace("GrafanaS3MetaReader.getKeys: OK took %vms +%v | %v", time.Since(rqStart).Milliseconds(), len(objs.Contents), s)
		}
		cl := len(objs.Contents)
		if cl > 0 {
			arr := make([]S3MetaObject, cl)
			for i, o := range objs.Contents {
				sm := S3MetaObject{}
				sm.SetTime(when)
				sm.SetMeta(o)
				arr[i] = sm
			}
			go gs.cachePut(deviceId, when, arr) //only catch when something is found
			return arr                          // we're only fetching a single slot in the bucket so first hit is enough
		}
	}
	return nil
}

const SEC_IN_DAY int64 = 24 * 60 * 60 // how many seconds in a day

func (gs *GrafanaS3MetaReader) cacheKey(did string, when time.Time) string {
	tbk := timeBucketUnix(when.UTC().Unix(), SEC_IN_DAY)
	return fmt.Sprintf("s3:did:{%v}:obj:dt:%v", did, tbk)
}

func (gs *GrafanaS3MetaReader) cachePut(deviceId string, when time.Time, objs []S3MetaObject) {
	buff, err := json.Marshal(objs)
	if err != nil {
		logDebug("GrafanaS3MetaReader.cachePut: unable to json serialize %v@%v", deviceId, when)
		return
	}

	k := gs.cacheKey(deviceId, when)
	m := map[string]interface{}{
		strconv.FormatInt(when.UTC().Unix(), 10): buff,
	}
	gs.redis.HMSet(k, m, gs.redisTTLS)
}

const TIME_BUCKETS_PER_DAY = SEC_IN_DAY / SEC_IN_5MIN

func (gs *GrafanaS3MetaReader) cacheFetch(deviceId string, start time.Time, end time.Time) map[time.Time][]S3MetaObject {
	procBegin := time.Now()
	ut := timeBucketUnix(start.UTC().Unix(), SEC_IN_5MIN) //unix time
	et := timeBucketUnix(end.UTC().Unix(), SEC_IN_5MIN)   //unix end time

	rKeys := make(map[string][]string)         //build cache key list
	dMap := make(map[time.Time][]S3MetaObject) //hold meta results per time-slot
	for dt := ut; dt < et; dt += SEC_IN_5MIN {
		d := time.Unix(dt, 0).UTC()
		dMap[d] = nil
		rk := gs.cacheKey(deviceId, d)
		uxDt := strconv.FormatInt(d.Unix(), 10)
		if rv, ok := rKeys[rk]; ok {
			rKeys[rk] = append(rv, uxDt)
		} else {
			rKeys[rk] = []string{uxDt}
		}
	}

	cacheHits := 0
	for k, v := range rKeys {
		if int64(len(v)) > TIME_BUCKETS_PER_DAY/4 { //over fetch
			if bMap, e := gs.redis.HGetAll(k); e == nil && len(bMap) > 0 {
				for _, bs := range bMap {
					if sok := gs.cacheFillBucket(bs, dMap); sok {
						cacheHits++
					}
				}
			}
		} else {
			if scm := gs.redis._client.HMGet(k, v...); scm != nil {
				if cr, e := scm.Result(); e == nil && len(cr) > 0 {
					for _, g := range cr {
						if g == nil {
							continue
						}
						bs := fmt.Sprint(g)
						if sok := gs.cacheFillBucket(bs, dMap); sok {
							cacheHits++
						}
					}
				}
			}
		}
	}
	logDebug("GrafanaS3MetaReader.cacheFetch: %vms %v/%v hits for %v %v - %v",
		time.Since(procBegin).Milliseconds(), cacheHits, len(dMap), deviceId, start.Format(DT_FORMAT_XML), end.Format(DT_FORMAT_XML))
	return dMap
}

func (gs *GrafanaS3MetaReader) cacheFillBucket(bs string, bucket map[time.Time][]S3MetaObject) bool {
	arr := gs.cacheDecode(bs)
	if len(arr) > 0 {
		kk := arr[0].GetTime()
		if vv, ok := bucket[kk]; ok && vv == nil { //protection from over fetching
			bucket[kk] = arr
			return true
		}
	}
	return false
}

func (gs *GrafanaS3MetaReader) cacheDecode(bs string) []S3MetaObject {
	if len(bs) == 0 {
		return nil
	}
	var arr []S3MetaObject
	if e := json.Unmarshal([]byte(bs), &arr); e == nil {
		return arr
	}
	logDebug("GrafanaS3MetaReader.cacheDecode: unable to deserialize json => %v", bs)
	return nil
}
