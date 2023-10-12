package main

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"golang.org/x/sync/semaphore"
)

const (
	ENVVAR_REBULK_KEY      = "FLO_REBULK_KEY"
	ENVVAR_REBULK_THREADS  = "FLO_REBULK_THREADS"
	DEFAULT_REBULK_THREADS = 4
)

// CreateReBulk logic to reprocess s3 files
func CreateReBulk(redis *RedisConnection, log *Logger) *reBulk {
	r := reBulk{
		redis:     redis,
		log:       log.CloneAsChild("reBulk"),
		queueKey:  getEnvOrDefault(ENVVAR_REBULK_KEY, "reBulk:q{1}"),
		ctx:       context.Background(),
		lastStat:  time.Now().Unix(),
		statFlush: time.Minute * 1,
		keyDur:    CreateKeyPerDuration(time.Hour),
	}
	if n, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_REBULK_THREADS, fmt.Sprint(DEFAULT_REBULK_THREADS))); n < 0 {
		r.threads = int32(DEFAULT_REBULK_THREADS)
	} else {
		r.threads = int32(n)
	}
	r.sem = semaphore.NewWeighted(int64(r.threads) * 2)
	if r.log.isDebug { //debug overrides
		r.statFlush = time.Second * 10
	}
	r.log.Notice("%v=%v", ENVVAR_REBULK_KEY, r.queueKey)
	r.log.Notice("%v=%v", ENVVAR_REBULK_THREADS, r.threads)
	if r.threads == 0 {
		r.log.Warn("logic is DISABLED")
	}
	return &r
}

// should fit ICloser interface
type reBulk struct {
	queueKey  string
	redis     *RedisConnection
	log       *Logger
	sem       *semaphore.Weighted //how many operations concurrently
	ctx       context.Context
	state     int32         //0 == closed, 1 == open
	threads   int32         //how many workers
	qCount    int64         //how many items queued by producer
	runCount  int64         //how many processed by consumer
	errCount  int64         //how many errors occurred
	lastStat  int64         //last time stats was printed
	statFlush time.Duration //how long between stat flushes
	keyDur    KeyPerDuration
}

func (r *reBulk) Open() {
	if atomic.CompareAndSwapInt32(&r.state, 0, 1) {
		r.log.Info("Opening")
		for i := 0; i < int(r.threads); i++ {
			go r.worker(fmt.Sprintf("%p_%v", r.worker, i))
			time.Sleep(time.Millisecond * 333)
		}
		r.log.Notice("Opened")
	}
}

func (r *reBulk) Close() {
	if atomic.CompareAndSwapInt32(&r.state, 1, 0) {
		r.log.Notice("Closed")
	}
}

func (r *reBulk) worker(threadName string) {
	r.log.Notice("worker[%v]: Started", threadName)
	defer r.log.Notice("worker[%v]: Ended", threadName)

	for r != nil && atomic.LoadInt32(&r.state) == 1 {
		cmd := r.redis._client.RPop(r.queueKey)
		if url, e := cmd.Result(); e != nil {
			if e.Error() != "redis: nil" {
				atomic.AddInt64(&r.errCount, 1)
				r.log.IfErrorF(e, "worker[%v]: key %v | %v", threadName, r.queueKey, e.Error())
				time.Sleep(time.Second * 5) //back off
			} else {
				time.Sleep(time.Second * 3) //back off a little on empty pop
			}
		} else if file, e := r.urlToFileSrc(url); e != nil {
			atomic.AddInt64(&r.errCount, 1)
			r.log.Warn("worker[%v]: urlToFileSrc %v", threadName, e.Error())
		} else {
			r.sem.Acquire(r.ctx, 1) //ensure we don't exceed out concurrent limits
			go func(f *BulkFileSource) {
				defer r.sem.Release(1)
				r.processFile(f)
			}(file)
		}
		r.logStatsFlush()
	}
}

func (r *reBulk) logStatsFlush() {
	now := time.Now().Unix()
	if lastPrint := atomic.LoadInt64(&r.lastStat); time.Duration(now-lastPrint)*time.Second >= r.statFlush {
		if atomic.CompareAndSwapInt64(&r.lastStat, lastPrint, now) { //double check guaranteed
			var (
				qCount   = atomic.SwapInt64(&r.qCount, 0)
				runCount = atomic.SwapInt64(&r.runCount, 0)
				errCount = atomic.SwapInt64(&r.errCount, 0)
				dur      = time.Duration(now-lastPrint) * time.Second
				durS     = dur.Seconds()
			)
			if qCount+runCount+errCount == 0 {
				return //nothing to print
			}
			r.log.Info("logStatsFlush: %v queued, %v processed, errors %v in %v | avg q/s=%v r/s=%v e/s=%v",
				qCount, runCount, errCount, fmtDuration(dur), float64(qCount)/durS, float64(runCount)/durS, float64(errCount)/durS)

			qCount = r.incRedis("reBulk:qCount", qCount)
			runCount = r.incRedis("reBulk:runCount", runCount)
			errCount = r.incRedis("reBulk:errCount", errCount)
			durS = float64(r.incRedis("reBulk:durS", int64(durS)))
			r.log.Notice("logStatsFlush: redisRunning qCount %v, runCount %v, errCount %v, durS %v | q/s=%v r/s=%v",
				qCount, runCount, errCount, durS, float64(qCount)/durS, float64(runCount)/durS)
		}
	}
}

func (r *reBulk) DeleteStats() {
	if _, e := r.redis.Delete("reBulk:qCount"); e != nil {
		r.log.IfWarnF(e, "DeleteStats: reBulk:qCount")
	}
	if _, e := r.redis.Delete("reBulk:runCount"); e != nil {
		r.log.IfWarnF(e, "DeleteStats: reBulk:runCount")
	}
	if _, e := r.redis.Delete("reBulk:errCount"); e != nil {
		r.log.IfWarnF(e, "DeleteStats: reBulk:errCount")
	}
	if _, e := r.redis.Delete("reBulk:durS"); e != nil {
		r.log.IfWarnF(e, "DeleteStats: reBulk:durS")
	}
}

type ReProcStats struct {
	Current int64         `json:"current"`
	Count   int64         `json:"count"`
	Runs    int64         `json:"runs"`
	Errors  int64         `json:"errors"`
	Dur     time.Duration `json:"dur"`
}

func (r *reBulk) GetStats() *ReProcStats {
	var (
		res = ReProcStats{Current: -1}
		cmd = r.redis._client.LLen(r.queueKey)
	)
	if n, e := cmd.Result(); e != nil {
		r.log.IfErrorF(e, "QueueSize: LLen")
	} else {
		res.Current = n
	}
	res.Count = r.getCounter("reBulk:qCount")
	res.Runs = r.getCounter("reBulk:runCount")
	res.Errors = r.getCounter("reBulk:errCount")
	res.Dur = time.Duration(r.getCounter("reBulk:durS")) * time.Second
	return &res
}

func (r *reBulk) getCounter(key string) (n int64) {
	if s, e := r.redis.Get(key); e != nil {
		r.log.IfWarnF(e, "getCounter: %v | redis", key)
	} else if x, e := strconv.Atoi(s); e != nil {
		r.log.IfWarnF(e, "getCounter: %v | strConv", key)
	} else {
		n = int64(x)
	}
	return n
}

const DUR_1_DAY_S = 24 * 60 * 60

func (r *reBulk) incRedis(key string, val int64) int64 {
	cmd := r.redis._client.IncrBy(key, val)
	if n, e := cmd.Result(); e != nil {
		r.log.IfWarnF(e, "incRedis: %v %v", key, val)
		return -1
	} else {
		if r.keyDur.Check(key, time.Minute*15) {
			if _, e = r.redis.Expire(key, DUR_1_DAY_S); e != nil {
				r.log.IfWarnF(e, "incRedis: %v | can't set TTL", key)
			}
		}
		return n
	}
}

func (_ *reBulk) urlToFileSrc(s3File string) (*BulkFileSource, error) {
	if strings.Index(strings.ToLower(s3File), "s3://") != 0 {
		return nil, errors.New("bad s3 file, uri has to begin with: s3://")
	} else {
		s3File = s3File[5:]
	}
	parts := strings.Split(s3File, "/")
	if len(parts) < 7 { //bad input
		return nil, errors.New("bad s3 path, too few folders (bucket,version,yyyy,MM,dd,hh-mm,did,etc...)")
	}
	f := BulkFileSource{Source: "api"}
	f.BucketName = parts[0]
	f.SourceUri, f.SchemaVersion, f.DeviceId = parseS3ObjectKey(strings.Join(parts[1:], "/"))
	if f.Date = f.DateBucket(); f.Date.Year() < 2000 {
		return nil, errors.New("bad s3 path, can't extract date")
	}
	f.Key = calcBulkFileSourceHash(&f)
	return &f, nil
}

func (r *reBulk) Queue(s3Files ...string) error {
	defer panicRecover(r.log, "Queue: %v", s3Files)
	var (
		urlLen = int64(len(s3Files))
		arr    = make([]interface{}, urlLen)
	)
	for i, url := range s3Files {
		arr[i] = url
	}

	cmd := r.redis._client.LPush(r.queueKey, arr...)
	if n, err := cmd.Result(); err != nil {
		return r.log.IfErrorF(err, "Queue: '%v' Failed %v | len=%v %v", r.queueKey, err.Error(), urlLen, s3Files)
	} else {
		r.log.Debug("Queue: '%v' OK for %v files", r.queueKey, n)
		return nil
	}
}

// re-process bulk append file only, don't re-publish notifications to Kafka, meant for API use to repair bulk data
func (r *reBulk) processFile(file *BulkFileSource) (err error) {
	start := time.Now() //v7 & v8 LF processing logic starts here
	defer panicRecover(r.log, "processFile: %v", file)

	mh, _ := mh3(file)
	if mh == "" {
		mh = file.Key
	}
	exp := 60 * 60
	if _log.isDebug {
		exp = 30
	}
	k := fmt.Sprintf("rebulk:s3:{%v}", mh)
	atomic.AddInt64(&r.runCount, 1)

	if ok, _ := _redis.SetNX(k, start.Unix(), exp); !ok {
		err = errors.New(r.log.Info("processFile: already processed s3://%v/%v", file.BucketName, file.SourceUri))
	} else if file.IsHfV8() {
		err = storeHiResFile(file)
	} else if loRes, e := pullLoResFile(file); e != nil {
		err = r.log.Warn("processFile: can't download file %v | %v", unEscapeUrlPath(file.SourceUri), e.Error())
	} else {
		err = storeLoResFile(file, loRes)
	}
	if err == nil {
		r.log.Trace("processFile: completed %vms %v", time.Since(start).Milliseconds(), file.SourceUri)
	} else {
		atomic.AddInt64(&r.errCount, 1)
	}
	return err
}
