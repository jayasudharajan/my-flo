package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"golang.org/x/sync/semaphore"

	"github.com/aws/aws-sdk-go/aws"
	aw "github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
)

const ENVVAR_GRAFANA_REDIS_CN = "FLO_GRAFANA_REDIS_CN"
const ENVVAR_S3_BULK_TELEMETRY_BUCKET = "FLO_S3_BULK_TELEMETRY_BUCKET"
const ENVVAR_S3_BULK_TELEMETRY_V8LF_PATH = "FLO_S3_BULK_TELEMETRY_V8LF_PATH"
const ENVVAR_S3_BULK_TELEMETRY_V8LF_EXT = "FLO_S3_BULK_TELEMETRY_V8LF_EXT"
const ENVVAR_S3_BULK_TELEMETRY_V7LF_PATH = "FLO_S3_BULK_TELEMETRY_V7LF_S3_PATH"
const ENVVAR_S3_TMP_PATH = "FLO_S3_TMP_PATH" //local scratch disk
const S3_REGION = "us-west-2"

// SEE: https://github.com/smcquay/jsonds
// SEE: https://github.com/grafana/grafana/blob/master/docs/sources/plugins/developing/datasources.md
// SEE: https://github.com/grafana/simple-json-backend-datasource

// GrafanaS3FileReader logic container
type GrafanaS3FileReader struct {
	redis               *RedisConnection
	redisPrivateCluster bool          //if true, cache will have much longer TTL
	redisTTL            time.Duration //how long to cache data

	S3Bucket   string   //bucket name
	S3V8Path   []string //csv+gz
	S3V8Ext    string
	S3V7Path   string //parquet+zippy
	awsSession *aw.Session
	s3DL       *s3manager.Downloader //s3 downloader
	WorkDir    string                //where temp files are stored

	_ctx       context.Context
	_ctxCancel context.CancelFunc
	_semRedis  *semaphore.Weighted
	_fileCount int64

	MetaReader *GrafanaS3MetaReader
}

func MustCreateDefaultGrafanaS3Reader() *GrafanaS3FileReader {
	redisCn := getEnvOrDefault(ENVVAR_GRAFANA_REDIS_CN, "")
	redisPrivateCluster := false
	if redisCn == "" { //fall back to ENVVAR_REDIS_CN
		redisCn = getEnvOrDefault(ENVVAR_REDIS_CN, "")
	} else {
		redisPrivateCluster = true
	}
	noMd5Check := true
	awsCfg := aws.Config{
		Region:                        aws.String(S3_REGION),
		S3DisableContentMD5Validation: &noMd5Check, //NOTE: to speed up s3 fetches, still safe, we will know if file is corrupted at parse time
	}
	bucket := getEnvOrDefault(ENVVAR_S3_BULK_TELEMETRY_BUCKET, "")
	v8Root := getEnvOrDefault(ENVVAR_S3_BULK_TELEMETRY_V8LF_PATH, "/tlm-:shard/v8.lf.csv.gz/")
	//TODO: remove v8ext & v7Root usage
	v8ext := getEnvOrDefault(ENVVAR_S3_BULK_TELEMETRY_V8LF_EXT, "v8.lf.csv.gz")
	v7Root := getEnvOrDefault(ENVVAR_S3_BULK_TELEMETRY_V7LF_PATH, "/telemetry-v7/")
	workDir := getEnvOrDefault(ENVVAR_S3_TMP_PATH, "")
	reader, e := CreateGrafanaS3Reader(redisCn, redisPrivateCluster, &awsCfg, bucket, v8Root, v8ext, v7Root, workDir)
	if e != nil {
		os.Exit(10)
	}
	return reader
}

var _ensurePermissionOnce int32 = 0

func CreateGrafanaS3Reader(
	redisCn string,
	redisPrivateCluster bool,
	awsCfg *aws.Config,
	s3Bucket string,
	s3V8Root string,
	s3V8ext string,
	s3V7Root string,
	workDir string) (*GrafanaS3FileReader, error) {
	if s3Bucket == "" {
		return nil, logError("CreateGrafanaS3Reader: s3Bucket is required")
	}
	if s3V8Root == "" {
		return nil, logError("CreateGrafanaS3Reader: s3V8Root is required")
	}
	if workDir == "" {
		workDir = "/tmp"
	} else if wl := len(workDir); wl > 1 && workDir[wl-1:wl] == "/" { //trailing /
		workDir = workDir[0 : wl-1] //truncate trailing slash
	}
	if atomic.CompareAndSwapInt32(&_ensurePermissionOnce, 0, 1) {
		if ef := ensureDirPermissionOK(workDir); ef != nil {
			return nil, ef
		}
	}
	g := GrafanaS3FileReader{
		S3Bucket:            s3Bucket,
		S3V8Path:            strings.Split(s3V8Root, ","),
		S3V7Path:            s3V7Root,
		S3V8Ext:             s3V8ext,
		WorkDir:             workDir,
		redisPrivateCluster: redisPrivateCluster,
	}
	g._ctx, g._ctxCancel = context.WithCancel(context.Background())
	g._semRedis = semaphore.NewWeighted(10)

	if strings.TrimSpace(redisCn) == "" {
		return nil, logError("CreateGrafanaS3Reader: redisCn is required")
	}
	red, err := CreateRedisConnection(redisCn)
	if err != nil {
		return nil, logError("main: unable to connect to redis. %v", err.Error())
	}
	g.redis = red
	if g.redisPrivateCluster {
		g.redisTTL = time.Duration(7*int(SEC_IN_DAY)) * time.Second
	} else {
		g.redisTTL = time.Duration(1*int(SEC_IN_DAY)) * time.Second
	}

	if awsCfg == nil {
		return nil, logError("CreateGrafanaS3Reader: awsCfg is required")
	}
	sess, err := aw.NewSession(awsCfg)
	if err != nil {
		return nil, logError("CreateGrafanaS3Reader: %v", err.Error())
	}
	g.awsSession = sess
	g.s3DL = s3manager.NewDownloader(g.awsSession) // use to download s3 objects
	g.MetaReader = g.CreateGrafanaS3MetaReader()
	return &g, nil
}

func (gs *GrafanaS3FileReader) Close() {
	if gs == nil {
		return
	}
	go gs.MetaReader.Close() //may not be necessary?
	gs._ctxCancel()          //don't wait just kill
	return
}

func (gs *GrafanaS3FileReader) Ping() error {
	return gs.MetaReader.Ping()
}

const DT_FORMAT_XML = "2006-01-02T15:04:05.000Z"

func (gs *GrafanaS3FileReader) GetRange(deviceId string, start time.Time, end time.Time) ([]S3Result, error) {
	if gs == nil {
		return nil, logError("GrafanaS3FileReader.GetRange: gs is nil")
	}
	gStart := time.Now()

	metas := gs.MetaReader.GetRange(deviceId, start, end) //will need this to know exact file name (with hash)
	ogBuckets := len(metas)
	if ogBuckets == 0 {
		logInfo("GrafanaS3FileReader.GetRange: %vms %v/%v buckets => %v rows | %v %v - %v",
			time.Now().Sub(gStart).Seconds(), 0, ogBuckets, 0, deviceId, start.Format(DT_FORMAT_XML), end.Format(DT_FORMAT_XML))
		return []S3Result{}, nil
	}

	rMap := gs.cacheFetch(deviceId, metas) //time slot key and result value
	if missingBuckets := gs.extractMissingBuckets(metas, rMap); len(missingBuckets) > 0 {
		ch := make(chan *S3Result)
		req, err := gs.prepBatchReq(deviceId, missingBuckets, ch) //now we can actually download telemetry v7 & v8 files
		if err == nil {
			iter := &s3manager.DownloadObjectsIterator{Objects: req}                            //s3 downloader hook is used to process each file as they come in
			if err := gs.s3DL.DownloadWithIterator(aws.BackgroundContext(), iter); err != nil { //trigger downloading files in parallel
				logWarn("GrafanaS3FileReader.GetRange: %v %v-%v => %v", deviceId, start.Format(DT_FORMAT_XML), end.Format(DT_FORMAT_XML), err.Error())
			}

			sent := len(iter.Objects)
			for sent > 0 {
				r := <-ch //processed file are received here
				if r == nil {
					sent--
				} else {
					rMap[r.StartTime] = r
				}
			}
		}
		close(ch)
	}
	res, rows := gs.collapseSort(rMap)
	logDebug("GrafanaS3FileReader.GetRange: %vs %v/%v buckets => %v rows | %v %v - %v",
		float32(time.Now().Sub(gStart).Milliseconds())/1000, len(rMap), ogBuckets, rows, deviceId, start.Format(DT_FORMAT_XML), end.Format(DT_FORMAT_XML))
	return res, nil
}

func (_ *GrafanaS3FileReader) extractMissingBuckets(metas []S3MetaObject, rMap map[time.Time]*S3Result) []S3MetaObject {
	cacheMiss := 0
	if ml := len(rMap); ml > 0 {
		missing := make([]S3MetaObject, 0, ml)
		for _, m := range metas {
			if rMap[m.GetTime()] == nil {
				missing = append(missing, m) //only copy what's missing over
				cacheMiss++
			}
		}
		return missing
	} // else, something F-up, continue with og metas arr, this works before caching
	return nil
}

func (_ *GrafanaS3FileReader) collapseSort(rMap map[time.Time]*S3Result) ([]S3Result, int) {
	res := make([]S3Result, len(rMap))
	ii := 0
	for _, r := range rMap {
		if r != nil {
			res[ii] = *r
			ii++
		}
	}
	res = res[0:ii] //trim array fat
	sort.Slice(res, func(i, j int) bool {
		return res[i].StartTime.UTC().Unix() < res[i].StartTime.UTC().Unix()
	})
	rows := 0
	for _, o := range res {
		rows += len(o.Telemetry)
	}
	return res, rows
}

type S3Result struct {
	Key       string          //s3 bucket key
	StartTime time.Time       //starting time of when data starts
	Telemetry []TelemetryData //decoded data
	LocalFile string          //where the local file is stored (empty of cached)
}

func containsPath(uri, path string) bool {
	if uri != "" && path != "" {
		if pl := len(path); pl > 0 && path[0:1] == "/" {
			path = path[1:pl]
		}
		if pl := len(path); pl > 0 && path[pl-1:pl] == "/" {
			path = path[0 : pl-1]
		}
		if strings.Contains(uri, path) {
			return true
		} else {
			return strings.Contains(strings.ToLower(uri), strings.ToLower(path)) //retry more expensive compare
		}
	}
	return false
}

func (gs *GrafanaS3FileReader) localFileName(deviceId string, m *S3MetaObject) (name string, version int) {
	var ext string
	if m.Key == "" {
		logWarn("GrafanaS3FileReader.localFileName: blank key @%v", deviceId)
		return "", 0
	} else if containsPath(m.Key, gs.S3V8Ext) {
		ext, version = "csv.gz", 8
	} else if containsPath(m.Key, gs.S3V7Path) {
		ext, version = "parquet.snappy", 7
	} else {
		logWarn("GrafanaS3FileReader.localFileName: unknown file type %v", m.Key)
		return "", 0
	}
	name = fmt.Sprintf("%v/%v_%v_%v.%v", gs.WorkDir, m.GetTime().Format("D20060102T1504"), deviceId, atomic.AddInt64(&gs._fileCount, 1), ext)
	return name, version
}

// /telemetry-v7/year=2020/month=03/day=13/hhmm=0000/deviceid=0479b7f85c55/0479b7f85c55.3b1893361706a18abf40032e7cae0db6d26e2939dee00b7d8647d8309339a50e.7.telemetry
func (gs *GrafanaS3FileReader) prepBatchReq(deviceId string, metas []S3MetaObject, resCh chan *S3Result) ([]s3manager.BatchDownloadObject, error) {
	logTrace("GrafanaS3FileReader.prepBatchReq: %v", deviceId)
	req := make([]s3manager.BatchDownloadObject, len(metas))
	i := 0
	for _, m := range metas {
		fName, fileVer := gs.localFileName(deviceId, &m)
		if fileVer == 0 {
			continue
		}

		file, e := os.OpenFile(fName, os.O_RDWR|os.O_CREATE|os.O_TRUNC, os.FileMode(0755))
		if e != nil {
			return nil, logWarn("GrafanaS3FileReader.prepBatchReq: %v", e.Error())
		}
		o := &s3.GetObjectInput{
			Bucket: aws.String(gs.S3Bucket),
			Key:    aws.String(m.Key),
		}
		dt := m.GetTime()
		req[i] = s3manager.BatchDownloadObject{
			Object: o,
			Writer: file,
			After: func() error {
				go gs.fileReceived(*o.Key, deviceId, fileVer, dt, file, resCh)
				return nil
			}}
		i++
	}
	return req[0:i], nil
}

func (gs *GrafanaS3FileReader) parseTelemetryFile(file *os.File, version int) (res []TelemetryData, closeDefer func()) {
	logTrace("GrafanaS3FileReader.parseTelemetryFile: ENTER ver%v %v", version, file.Name())
	switch version {
	case 8:
		res, closeDefer, _ = new(TelemetryV8).ReadAllFromFile(file)
	case 7:
		res, closeDefer, _ = new(TelemetryV7).ReadAllFromFile(file)
	default:
		logError("GrafanaS3FileReader.parseTelemetryFile: un-supported file type %v", file.Name())
	}
	logTrace("GrafanaS3FileReader.parseTelemetryFile: EXIT %v | rows %v", file.Name(), len(res))
	return res, closeDefer
}

func (gs *GrafanaS3FileReader) fileReceived(
	key string,
	deviceId string,
	fileVer int,
	ts time.Time,
	file *os.File,
	resCh chan *S3Result) { //call back when a single file is fully downloaded from s3

	logTrace("GrafanaS3FileReader.fileReceived: %v", key)
	if file == nil {
		return
	}
	if resCh == nil {
		go gs.fileCleanup(file)
		return
	}
	defer func(ch chan *S3Result) { //send done signal
		if ch != nil {
			ch <- nil
		}
	}(resCh)

	telArr, closer := gs.parseTelemetryFile(file, fileVer)
	if len(telArr) == 0 {
		go func() { closer(); gs.fileCleanup(file) }()
		return //already logged
	}
	r := S3Result{
		Key:       key,
		StartTime: ts,
		Telemetry: telArr,
		LocalFile: file.Name(),
	}
	go gs.cachePut(r, deviceId, file, closer)
	if resCh != nil {
		resCh <- &r
	}
}

func (_ *GrafanaS3FileReader) fileCleanup(f *os.File) {
	logTrace("GrafanaS3FileReader.fileCleanup: %v", f)
	if f != nil {
		f.Close()
		os.Remove(f.Name())
	}
}

func (gs *GrafanaS3FileReader) cacheKey(did string, when time.Time) string {
	return fmt.Sprintf("s3:did:{%v}:file:dt:%v", did, when.UTC().Unix())
}

func (gs *GrafanaS3FileReader) cachePut(r S3Result, did string, file *os.File, closer func()) {
	logTrace("GrafanaS3FileReader.cachePut: %v", r.LocalFile)
	defer func() { closer(); gs.fileCleanup(file) }()
	if r.LocalFile == "" || file == nil {
		logWarn("GrafanaS3FileReader.cachePut: file is missing for %v", r.Key)
		return
	}
	if _, e := file.Seek(0, 0); e != nil {
		logWarn("GrafanaS3FileReader.cachePut: can't seek %v", r.LocalFile)
		return
	}
	buff, e := ioutil.ReadAll(file)
	if e != nil {
		logInfo("GrafanaS3FileReader.cachePut: can't read %v", r.LocalFile)
		return
	}
	if len(buff) == 0 {
		logDebug("GrafanaS3FileReader.cachePut: empty file %v", r.LocalFile)
		return
	}

	k := gs.cacheKey(did, r.StartTime)
	gs._semRedis.Acquire(gs._ctx, 1) //ensure we don't go beyond concurrent limit
	rr := gs.redis._client.Set(k, buff, gs.redisTTL)
	gs._semRedis.Release(1)

	if er := rr.Err(); er != nil {
		logWarn("GrafanaS3FileReader.cachePut: can't set %v | %v", r.LocalFile, er.Error())
		return
	}
}

func (gs *GrafanaS3FileReader) cacheFillBucket(did string, m S3MetaObject, mux *sync.Mutex, bucket map[time.Time]*S3Result, wg *sync.WaitGroup) {
	logTrace("GrafanaS3FileReader.cacheFillBucket: ENTER %v", m.Key)
	defer wg.Done()

	fileName, ver := gs.localFileName(did, &m)
	if ver == 0 {
		return //already logged
	}
	file, e := os.OpenFile(fileName, os.O_RDWR|os.O_CREATE|os.O_TRUNC, os.FileMode(0755))
	if e != nil {
		logWarn("GrafanaS3FileReader.cacheFillBucket: can't create file %v => %v", fileName, e.Error())
		return
	}
	defer gs.fileCleanup(file)

	dt := m.GetTime()
	cacheKey := gs.cacheKey(did, dt)
	gs._semRedis.Acquire(gs._ctx, 1) //ensure we don't go beyond concurrent limit
	cr := gs.redis._client.Get(cacheKey)
	gs._semRedis.Release(1)

	if s, e := cr.Result(); e == nil && s != "" {
		if n, e := file.WriteString(s); e != nil {
			logWarn("GrafanaS3FileReader.cacheFillBucket: can't write file sz=%v %v => %v", n, fileName, e.Error())
			return
		} else {
			telArr, closer := gs.parseTelemetryFile(file, ver)
			defer closer()
			if len(telArr) == 0 {
				return //already logged
			} else if bucket == nil {
				logWarn("GrafanaS3FileReader.cacheFillBucket: bucket nil | file %v", fileName)
				return
			} else {
				r := S3Result{
					Key:       m.Key,
					StartTime: dt,
					Telemetry: telArr,
					LocalFile: fileName,
				}
				mux.Lock()
				bucket[dt] = &r
				mux.Unlock()

				logTrace("GrafanaS3FileReader.cacheFillBucket: bucket set OK | file %v", r.LocalFile)
				return
			}
		}
	} else {
		logTrace("GrafanaS3FileReader.cacheFillBucket: EXIT %v | %v %v", m.Key, s, e)
	}
}

func minTime(a, b time.Time) time.Time {
	if a.After(b) {
		return b
	} else {
		return a
	}
}

func maxTime(a, b time.Time) time.Time {
	if a.After(b) {
		return a
	} else {
		return b
	}
}

func (gs *GrafanaS3FileReader) cacheFetch(deviceId string, metas []S3MetaObject) map[time.Time]*S3Result {
	logTrace("GrafanaS3FileReader.cacheFetch: ENTER %v", deviceId)
	started := time.Now()
	bucket := make(map[time.Time]*S3Result)
	metaMap := make(map[time.Time]*S3MetaObject) //quick lookup of meta info

	wg := sync.WaitGroup{}
	var minDt, maxDt time.Time
	for i, m := range metas {
		dt := m.GetTime()
		if i == 0 {
			minDt = dt
			maxDt = dt
		} else {
			minDt = minTime(minDt, dt)
			maxDt = maxTime(maxDt, dt)
		}
		metaMap[dt] = &m
		bucket[dt] = nil
	}
	var mux sync.Mutex
	for _, m := range metas {
		go gs.cacheFillBucket(deviceId, m, &mux, bucket, &wg)
		wg.Add(1)
	}
	wg.Wait() //wait all
	hits := 0
	for _, v := range bucket {
		if v != nil {
			hits++
		}
	}
	logDebug("GrafanaS3FileReader.cacheFetch: %vms %v/%v hits for %v %v - %v",
		time.Since(started).Milliseconds(), hits, len(bucket), deviceId, minDt.Format(DT_FORMAT_XML), maxDt.Format(DT_FORMAT_XML))
	return bucket
}
