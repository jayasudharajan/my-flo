package main

import (
	"errors"
	"fmt"
	"math/rand"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis"

	"github.com/aws/aws-sdk-go/aws/session"
)

const (
	ENVVAR_CONCAT_RECOVER_MAX_PULL_BATCH = "FLO_CONCAT_RECOVER_MAX_PULL_BATCH"
	ENVVAR_CONCAT_RECOVER_DISABLE        = "FLO_CONCAT_RECOVER_DISABLE"
	ENVVAR_S3_TELEMETRY_BUCKET           = "FLO_S3_BULK_TELEMETRY_BUCKET"
)

var (
	CONCAT_RECOVER_MAX_WAIT_MIN     float64 = 10
	CONCAT_RECOVER_MAX_PULL_BATCH   int32   = 50
	CONCAT_RECOVER_MAX_PULL_SHARD   int32   = CONCAT_RECOVER_MAX_PULL_BATCH * 4
	CONCAT_RECOVER_MAX_HISTORY_HOUR int64   = 24 * 8
	S3_TELEMETRY_BUCKET                     = ""

	_recvMutex          = sync.RWMutex{}
	_recvLastPull       = time.Now().UTC().Unix()
	_recChkOnce   int32 = 0
	_recPollSec   int32 = 30
	_fileOK             = false
)

func init() {
	n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_CONCAT_RECOVER_MAX_PULL_BATCH, ""))
	if e == nil && n > 0 {
		if n >= int(CONCAT_MAX_BATCH) {
			CONCAT_RECOVER_MAX_PULL_BATCH = int32(n)
		} else { //minimum
			CONCAT_RECOVER_MAX_PULL_BATCH = CONCAT_MAX_BATCH
		}
	}
	_recvLastPull -= int64(CONCAT_RECOVER_MAX_WAIT_MIN*60) + (60 * 5) //will start in 5min
	_log.Notice("%v=%v", ENVVAR_CONCAT_RECOVER_MAX_PULL_BATCH, CONCAT_RECOVER_MAX_PULL_BATCH)
	ms := getEnvOrDefault("FLO_CONCAT_RECOVER_MAX_PULL_SHARD", "")
	if m, _ := strconv.ParseInt(ms, 10, 64); m >= int64(CONCAT_RECOVER_MAX_PULL_BATCH) {
		CONCAT_RECOVER_MAX_PULL_SHARD = int32(m)
	}
	_log.Notice("CONCAT_RECOVER_MAX_PULL_SHARD=%v", CONCAT_RECOVER_MAX_PULL_SHARD)

	recvPoll, _ := strconv.Atoi(getEnvOrDefault("FLO_RECOVERY_POLL_SEC", "60"))
	if recvPoll < 10 {
		recvPoll = 10 //min allowed!
	}
	_recPollSec = int32(recvPoll)
	_log.Notice("FLO_RECOVERY_POLL_SEC=%v", _recPollSec)
}

type bulkRecover struct {
	redis *RedisConnection
	s3s   *session.Session
	log   *Logger
}

func CreateBulkRecover(redis *RedisConnection, aws *session.Session, log *Logger) *bulkRecover {
	l := log.CloneAsChild("recover")
	if strings.EqualFold(getEnvOrDefault(ENVVAR_CONCAT_RECOVER_DISABLE, ""), "true") {
		l.Warn("BulkRecover DISABLED, %v=true", ENVVAR_CONCAT_RECOVER_DISABLE)
		return nil
	}
	if atomic.CompareAndSwapInt32(&_recChkOnce, 0, 1) {
		if S3_TELEMETRY_BUCKET == "" {
			S3_TELEMETRY_BUCKET = getEnvOrDefault(ENVVAR_S3_TELEMETRY_BUCKET, "")
		}
		if e := ensureDirPermissionOK(CONCAT_PATH); e != nil {
			l.Warn("full permission required @ %v", CONCAT_PATH)
		} else {
			_fileOK = true
			l.Notice("%v=%v", ENVVAR_S3_TELEMETRY_BUCKET, S3_TELEMETRY_BUCKET)
		}
		if S3_TELEMETRY_BUCKET == "" || !_fileOK {
			l.Warn("recover DISABLED")
		}
	}
	if S3_TELEMETRY_BUCKET == "" || !_fileOK {
		return nil
	}
	return &bulkRecover{redis: redis, s3s: aws, log: l}
}

func (b *bulkRecover) appender(bucket string) *bulkAppender {
	if b == nil {
		return nil
	}
	return CreateBulkAppender(b.redis, b.s3s, bucket, b.log)
}

func (b *bulkRecover) Schedule(cancelSignal *int32) { //periodically pull
	if b == nil {
		return
	}
	b.log.PushScope("sched")
	defer b.log.PopScope()
	if !b.log.isDebug {
		rand.Seed(time.Now().UnixNano())
		r := rand.Intn(int(_recPollSec)) //randomly sleep on boot to space out zrange requests on pulls
		b.log.Debug("sleeping %vs before starting", r)
		time.Sleep(time.Duration(r) * time.Second)
	}
	b.log.Info("starting")
	defer b.log.Info("exiting")

	sleepDur := time.Duration(_recPollSec) * time.Second
	for atomic.LoadInt32(cancelSignal) == 0 {
		if count, e := b.Pull(); e != nil || count == 0 {
			time.Sleep(sleepDur) //full sleep on empty or err
		}
		time.Sleep(sleepDur / 10)
	}
}

func (b *bulkRecover) Dispose() {} //dummy dispose to fit IDisposable interface

func (b *bulkRecover) canPull() (curRun int64, ok bool) {
	lastRun := atomic.LoadInt64(&_recvLastPull)
	curRun = time.Now().UTC().Unix()
	if dd := time.Duration(curRun-lastRun) * time.Second; dd.Minutes() >= CONCAT_RECOVER_MAX_WAIT_MIN {
		if atomic.CompareAndSwapInt64(&_recvLastPull, lastRun, curRun) { //another process already picked it up
			return curRun, true
		}
	}
	return 0, false
}

func (b *bulkRecover) Pull() (int32, error) {
	started := time.Now()
	if b == nil {
		return 0, errors.New("nil source binding: bulkRecover.Pull(...)")
	}
	defer panicRecover(b.log, "Pull")
	_recvMutex.Lock()
	defer _recvMutex.Unlock()
	curRun, ok := b.canPull()
	if !ok { //another process already picked it up
		return 0, nil
	}

	b.log.PushScope("Pull")
	defer b.log.PopScope()
	b.log.Debug("Starting")
	var (
		pull, recvCount int32
		eArr            []error
		loopAgain             = true
		loopCount       int32 = 0
		wg              sync.WaitGroup
		errLock         = sync.RWMutex{}
	)
	for loopAgain {
		loopAgain = false
		if zRes, noWait, e := b.zChunk(curRun); len(zRes) != 0 {
			if pullCount := int32(len(zRes)); pullCount != 0 {
				pull += pullCount
				toRecover := b.toBulkFileSrcArr(zRes)
				wg.Add(1)
				go func(w *sync.WaitGroup) {
					defer w.Done()
					defer panicRecover(b.log, "Pull->Recover")
					if fixed, er := b.Recover(toRecover); er != nil {
						errLock.Lock()
						eArr = append(eArr, er)
						errLock.Unlock()
					} else {
						atomic.AddInt32(&recvCount, fixed)
					}
				}(&wg)
			}
			if noWait {
				loopAgain = true
				loopCount++
				b.log.Debug("looped %v | pull=%v recvCount=%v | errs=%v", loopCount, pull, recvCount, len(eArr))
			}
		} else if e != nil {
			errLock.Lock()
			eArr = append(eArr, e)
			errLock.Unlock()
		}
	}
	b.log.Debug("Done w/ loop, waiting for recovery ops")
	wg.Wait()
	var (
		logMsg = "pulled: %vs started @%v | pull=%v recvCount=%v"
		err    = wrapErrors(eArr)
	)
	if err != nil {
		logMsg += fmt.Sprintf(" with ERROR: %v", err.Error())
	}
	b.log.Info(logMsg, float32(time.Since(started).Milliseconds())/1000, started.Format(time.RFC3339), pull, recvCount)
	return pull, err
}

func (b *bulkRecover) zChunk(curRunUx int64) ([]redis.Z, bool, error) {
	b.log.PushScope("zChunk")
	defer b.log.PopScope()
	var (
		start  = time.Now()
		es     = make([]error, 0)
		res    = make([]redis.Z, 0)
		shards = strings.Split(HEX_CHARS, "")
		nwMax  = int(float64(int(CONCAT_RECOVER_MAX_PULL_SHARD)*len(shards)) * 0.4) //no sleep if total fetch is more than this
		noWait = false
	)
	for _, sh := range shards {
		arr, e := b.zRange(sh, curRunUx)
		if len(arr) != 0 {
			res = append(res, arr...)
		}
		if e != nil {
			es = append(es, e)
		}
	}
	if size := len(res); size >= nwMax {
		noWait = true
	}
	b.log.Debug("found=%v noWait=%v took=%v errs=%v", len(res), noWait, time.Since(start).String(), len(es))
	return res, noWait, wrapErrors(es)
}

func (b *bulkRecover) zRange(shard string, curRunUx int64) ([]redis.Z, error) {
	b.log.PushScope("zRange", shard)
	defer b.log.PopScope()
	var (
		started                         = time.Now()
		offset                          = time.Duration(CONCAT_RECOVER_MAX_WAIT_MIN) * time.Minute
		endS                            = time.Unix(curRunUx, 0).UTC().Add(-offset).Truncate(time.Minute)
		startS                          = endS.Add(time.Duration(-CONCAT_RECOVER_MAX_HISTORY_HOUR) * time.Hour)
		batchFound, i, foundTotal int32 = 0, 0, 0
		es                              = make([]error, 0)
		zRes                            = make([]redis.Z, 0)
		shardKey                        = fmt.Sprintf("%v:{%v}", CONCAT_REDIS_KEY, strings.ToLower(shard))
	)
	if b.log.isDebug {
		endS = time.Now().UTC()
	}
	op := redis.ZRangeBy{Min: fmt.Sprint(startS.Unix()), Max: fmt.Sprint(endS.Unix()), Count: int64(CONCAT_RECOVER_MAX_PULL_BATCH)}
	for (i == 0 || batchFound == CONCAT_RECOVER_MAX_PULL_BATCH) && foundTotal < CONCAT_RECOVER_MAX_PULL_SHARD {
		i++
		cmd := b.fetchZOffset(shardKey, &op)
		if zr, e := cmd.Result(); e != nil {
			if e.Error() == "redis: nil" { //list not found
				break
			} else {
				es = append(es, b.log.IfWarnF(e, "%v | %v", shardKey, op))
				break
			}
		} else if zl := len(zr); zl == 0 { //list empty
			b.resetZOffset(shardKey)
			break
		} else { //found things to recover
			batchFound = int32(zl)
			foundTotal += batchFound
			zRes = append(zRes, zr...)
			if batchFound == CONCAT_RECOVER_MAX_PULL_BATCH { //full batch, sleep a little to ease congestion on redis
				time.Sleep(time.Millisecond * 2)
			}
		}
	}
	var (
		ll     = LL_TRACE
		took   = time.Since(started)
		found  = len(zRes)
		errors = len(es)
	)
	if errors > 0 {
		ll = LL_WARN
	} else if took > time.Second || found > 0 {
		ll = LL_DEBUG
	}
	b.log.Log(ll, "found %v took %v | errs=%v", found, took, errors)
	return zRes, wrapErrors(es)
}

func (b *bulkRecover) resetZOffset(shardKey string) {
	start := time.Now()
	//_fetchFileSemaphore.Acquire(_bulkCtx, 1)
	//defer _fetchFileSemaphore.Release(1)

	ko := b.offsetKey(shardKey)
	if _, e := b.redis.Delete(ko); e != nil && e != redis.Nil {
		b.log.IfErrorF(e, "resetZOffset: %v took=%v", ko, time.Since(start))
	} else {
		var (
			took = time.Since(start)
			ll   = LL_TRACE
		)
		if took > time.Second {
			ll = LL_DEBUG
		}
		b.log.Log(ll, "resetZOffset: OK %v took=%v", ko, took)
	}
}

func (b *bulkRecover) offsetKey(shardKey string) string {
	return fmt.Sprintf("%s:offset", shardKey)
}

func (b *bulkRecover) fetchZOffset(shardKey string, op *redis.ZRangeBy) *redis.ZSliceCmd {
	start := time.Now()
	//_fetchFileSemaphore.Acquire(_bulkCtx, 1)
	//defer _fetchFileSemaphore.Release(1)

	var (
		ko       = b.offsetKey(shardKey)
		cmd      = b.redis._client.IncrBy(ko, op.Count) //split the work load w/ other instances
		offsetOk = "OK"
		ll       = LL_TRACE
	)
	if n, e := cmd.Result(); e != nil && e != redis.Nil {
		op.Offset += op.Count //local inc for safety
		offsetOk = "FAILED"
		ll = LL_WARN
	} else {
		op.Offset = n
	}
	var (
		res  = b.redis._client.ZRangeByScoreWithScores(shardKey, *op)
		took = time.Since(start)
	)
	if ll == LL_TRACE && took > time.Second {
		ll = LL_DEBUG
	}
	b.log.Log(ll, "fetchZOffset: %v %v newOffset=%v took=%v found=%v", offsetOk, ko, op.Offset, took, len(res.Val()))
	return res
}

func (b *bulkRecover) toBulkFileSrcArr(arr []redis.Z) map[string]BulkFileSource {
	res := make(map[string]BulkFileSource)
	for _, z := range arr {
		if m, e := b.toBulkFileSrc(&z); e == nil && m != nil {
			rs := fmt.Sprint(z.Member)
			res[rs] = *m
		}
	}
	return res
}

//20200424-1858-782A85D15A44.235b15fbdda9d68d5a270509042cb43a.8.lf.csv
//telemetry-v8.lf.csv.gz/year=2020/month=04/day=24/hhmm=1158/deviceid=782A85D15A44/782A85D15A44.235b15fbdda9d68d5a270509042cb43a.8.lf.csv.gz.telemetry
//telemetry-v7/year=2020/month=02/day=11/hhmm=0500/deviceid=0c1c57af7707/0c1c57af7707.e0ff305ff645eca319aad3b9c5afce07ddfd11ac02386c4c8ca3d5752ca20f49.7.telemetry
func (b *bulkRecover) toBulkFileSrc(z *redis.Z) (*BulkFileSource, error) {
	rs := fmt.Sprint(z.Member)
	var err error
	if strings.Contains(rs, TELEMETRY_EXT) {
		if dt := time.Unix(int64(z.Score), 0).Truncate(time.Minute).UTC(); dt.Year() > 2000 {
			return rebuildBulkFileSource(rs, dt)
		} else {
			err = b.log.Warn("bad date in key | %v", z)
		}
	} else { //something's wrong!
		err = b.log.Warn("bad redis key | %v", z)
	}
	if app := b.appender(CONCAT_S3_BUCKET_LF); app != nil {
		app.zGroupRm(rs) //rm key on err. NOTE: any bucket is fine here, none bucket specific operation
	}
	return nil, err
}

func (b *bulkRecover) Recover(nameMap map[string]BulkFileSource) (recoverCount int32, err error) {
	started := time.Now()
	b.log.PushScope("Recover")
	defer b.log.PopScope()

	if len(nameMap) == 0 {
		return 0, errors.New("nothing to recover, nameMap is empty")
	}
	bucketCounter := make(map[string]int)
	for name, meta := range nameMap {
		if !meta.IsV8() {
			b.log.Info("Rejecting %v", name)
			continue
		}
		bucket := CONCAT_S3_BUCKET_LF
		if meta.IsHfV8() {
			bucket = CONCAT_S3_BUCKET_HF
		}
		if app := b.appender(bucket); app == nil {
			b.log.Warn("Can't get appender for bucket %v -> %v", bucket, name)
			continue
		} else if ok, _ := app.InProgressCheck(name); ok { //we can clean up now
			if e := b.pipeS3toLocalCsvGz(name, &meta, app); e != nil {
				err = e
				continue
			}
			recoverCount++
			b.log.Debug("recvApn: %v @ %v", name, meta.Date)
			if bc, good := bucketCounter[bucket]; good {
				bucketCounter[bucket] = bc + 1
			} else {
				bucketCounter[bucket] = 1
			}
			delete(nameMap, name)
		} else { //another process picked up the work
			continue
		}
	}
	b.log.Debug("%vs fixed=%v un-processed=%v | %v", time.Since(started).Milliseconds()/1000, recoverCount, len(nameMap), bucketCounter)
	return recoverCount, err
}

func (b *bulkRecover) pipeS3toLocalCsvGz(name string, meta *BulkFileSource, app *bulkAppender) error {
	var csv interface{}
	if meta.IsV8() {
		if meta.IsHfV8() {
			if hiRes, e := downloadHiResV8(meta); e != nil {
				app.zGroupRm(name)
				return e
			} else {
				es := make([]error, 0)
				for _, chunk := range hiRes {
					csv = chunk
					if e = app.StoreCsv(false, meta, csv, int32(len(chunk))); e != nil { //no dup check because it's done in parent func
						es = append(es, e)
					}
				}
				return wrapErrors(es)
			}
		} else {
			key := unEscapeUrlPath(meta.SourceUri)
			if loRes, e := downloadLoResV8(meta.BucketName, key); e != nil {
				app.zGroupRm(name)
				return e
			} else {
				csv = gpmToGpsBulkFix(loRes)
				e = app.StoreCsv(false, meta, csv, int32(len(loRes))) //no dup check because it's done in parent func
				return e
			}
		}
	} else { //assumes v7
		if loRes, e := downloadLoResV7(meta); e != nil {
			app.zGroupRm(name)
			return e
		} else {
			csv = gpmToGpsBulkFix(loRes)
			e = app.StoreCsv(false, meta, csv, int32(len(loRes))) //no dup check because it's done in parent func
			return e
		}
	}
}

type recoverStats struct {
	Now    string           `json:"now,omitempty"`
	Shards map[string]int64 `json:"shards"`
	Sum    int64            `json:"shardSum"`
}

func (b *bulkRecover) Stats() (*recoverStats, error) {
	var (
		start  = time.Now()
		shards = strings.Split(HEX_CHARS, "")
		es     = make([]error, 0)
		res    = recoverStats{Shards: make(map[string]int64)}
	)
	for _, sh := range shards {
		var (
			k   = fmt.Sprintf("%s:{%s}", CONCAT_REDIS_KEY, sh)
			cmd = b.redis._client.ZCard(k)
		)
		if n, e := cmd.Result(); e != nil && e != redis.Nil {
			b.log.IfErrorF(e, "QueueCount: %v", k)
			es = append(es, e)
		} else if n > 0 {
			res.Shards[k] = n
			res.Sum += n
		}
	}
	res.Now = time.Now().UTC().Format(time.RFC3339)
	b.log.Debug("Stats: sum=%v took=%v", res.Sum, time.Since(start))
	return &res, wrapErrors(es)
}

func (b *bulkRecover) Truncate(older time.Time) (*recoverStats, error) {
	var (
		start  = time.Now()
		offset = time.Duration(CONCAT_RECOVER_MAX_WAIT_MIN) * time.Minute
		cutOff = time.Now().UTC().Truncate(time.Minute).Add(-offset)
		shards = strings.Split(HEX_CHARS, "")
		es     = make([]error, 0)
		res    = recoverStats{Shards: make(map[string]int64)}
	)
	if older = older.UTC(); older.After(cutOff) {
		b.log.Debug("Truncate: can't remove before %v adjusting input %v", cutOff, older)
		older = cutOff //don't remove before this cutoff for safety reasons
	}
	for _, sh := range shards {
		var (
			k   = fmt.Sprintf("%s:{%s}", CONCAT_REDIS_KEY, sh)
			val = fmt.Sprint(older.UTC().Unix() - 1)
			cmd = b.redis._client.ZRemRangeByScore(k, "-inf", val)
		)
		if n, e := cmd.Result(); e != nil && e != redis.Nil {
			b.log.IfErrorF(e, "Truncate: %v older=%v", k, older)
			es = append(es, e)
		} else if n > 0 {
			b.log.Debug("Truncate: %v older=%v removed=%v", k, older, n)
			res.Shards[k] = n
			res.Sum += n
		}
	}
	b.log.Notice("Truncate: older=%v removed=%v took=%v", older, res.Sum, time.Since(start))
	return &res, wrapErrors(es)
}
