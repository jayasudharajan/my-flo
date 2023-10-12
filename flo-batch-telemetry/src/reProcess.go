package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"golang.org/x/sync/semaphore"

	"github.com/go-redis/redis"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

const ENVVAR_REPROCESS_TOPIC = "FLO_REPROCESS_TOPIC"

type reProcess struct {
	kafka   *KafkaConnection
	kTopic  string
	kGroup  string
	kSub    *KafkaSubscription
	log     *Logger
	state   int32 //0=closed, 1=opened
	sleep   time.Duration
	threads int32
	sem     *semaphore.Weighted
	ctx     context.Context

	redis   *RedisConnection
	success int64 //stats
	errors  int64
	flushed int64
}

// CreateReProcess create logic to reprocess s3 files
func CreateReProcess(kafka *KafkaConnection, redis *RedisConnection, log *Logger) *reProcess {
	r := reProcess{
		log:     log.Clone().SetName("reProcess"),
		kafka:   kafka,
		kTopic:  getEnvOrDefault(ENVVAR_REPROCESS_TOPIC, "telemetry-reprocess"),
		kGroup:  getEnvOrDefault(ENVVAR_KAFKA_GROUP, "telemetry-re-proc-grp"),
		flushed: time.Now().Unix(),
		redis:   redis,
		sleep:   time.Millisecond * 20,
		threads: 2,
		ctx:     context.Background(),
	}
	if n, _ := strconv.Atoi(getEnvOrDefault("FLO_REPROCESS_SLEEP_MS", "")); n > 0 {
		r.sleep = time.Duration(n) * time.Millisecond
	}
	if n, e := strconv.Atoi(getEnvOrDefault("FLO_REPROCESS_THREADS", "")); e == nil && n >= 0 {
		r.threads = int32(n)
	}
	if r.threads > 0 {
		r.sem = semaphore.NewWeighted(int64(r.threads))
		r.log.Notice("FLO_REPROCESS_THREADS=%v", r.threads)
	} else {
		r.log.Warn("FLO_REPROCESS_THREADS=0 reprocessing is DISABLED")
	}
	r.log.Notice("%v=%v", ENVVAR_REPROCESS_TOPIC, r.kTopic)
	r.log.Notice("FLO_REPROCESS_SLEEP_MS=%v", r.sleep)
	return &r
}

func (r *reProcess) PingKafka() error {
	var e error
	if r.kSub != nil && r.kSub.Consumer != nil {
		_, e = r.kSub.Consumer.GetMetadata(&r.kTopic, false, 1000)
	} else if r.kafka != nil && r.kafka.Producer != nil {
		_, e = r.kafka.Producer.GetMetadata(&r.kTopic, false, 1000)
	} else {
		e = errors.New("subscriber & consumer are missing")
	}
	r.log.IfErrorF(e, "PingKafka")
	return e
}

func (r *reProcess) Open() {
	if r != nil && r.threads > 0 && atomic.CompareAndSwapInt32(&r.state, 0, 1) {
		go RetryIfError(r.subscribe, time.Second*10, r.log)
	}
}

func (r *reProcess) subscribe() (e error) {
	if atomic.LoadInt32(&r.state) != 1 {
		return nil
	}
	if r.kSub != nil {
		r.kSub.Close()
	}
	if r.kSub, e = r.kafka.Subscribe(r.kGroup, []string{r.kTopic}, r.processFile); e != nil {
		r.log.Warn("Open: can't subscribe topic %v as %v, will retry", r.kTopic, r.kGroup)
	} else {
		go r.flusher()
		r.log.Notice("Open: OK")
	}
	return
}

func (r *reProcess) flusher() {
	for atomic.LoadInt32(&r.state) == 1 {
		now := time.Now().Unix()
		if last := atomic.LoadInt64(&r.flushed); last+60 >= now { //flush every 60s
			if atomic.CompareAndSwapInt64(&r.flushed, last, now) { //got flush lock
				r.flushStats()
			}
		}
		time.Sleep(time.Second * 10)
	}
}

func (r *reProcess) Close() {
	if r != nil && atomic.CompareAndSwapInt32(&r.state, 1, 0) {
		if r.kSub != nil {
			r.kSub.Close()
		}
		r.flushStats()
		r.log.Notice("Close: OK")
	}
}

func (r *reProcess) processFile(item *kafka.Message) {
	defer panicRecover(r.log, "processFile: for %v", item.Key)
	r.log.PushScope("processFile", string(item.Key))
	defer r.log.PopScope()

	if len(item.Key) != 12 || item.Value == nil {
		return
	}
	f := BulkFileSource{}
	if e := json.Unmarshal(item.Value, &f); e != nil {
		atomic.AddInt64(&r.errors, 1)
		r.log.IfErrorF(e, "can't deserialize: %s", item.Value)
	} else if len(f.DeviceId) != 12 || f.DateBucket().Year() < 2000 {
		atomic.AddInt64(&r.errors, 1)
		r.log.IfWarnF(e, "bad file %v", f)
	} else {
		if e = r.sem.Acquire(r.ctx, 1); e == nil {
			go func(file *BulkFileSource) {
				defer r.sem.Release(1)
				defer panicRecover(r.log, "processFile", f.SourceUri)
				r.job(file)
			}(&f)
		} else {
			r.log.IfWarnF(e, "can't acquire sem")
		}
		time.Sleep(r.sleep)
	}
}

func (r *reProcess) job(b *BulkFileSource) {
	workerId := fmt.Sprintf("rp_%p", r)
	processKafkaFile(b, true, true, "reProcessed", workerId)
	success := atomic.AddInt64(&r.success, 1)
	if c := success + atomic.LoadInt64(&r.errors); c%20 == 0 {
		go r.flushStats()
	}
}

func (*reProcess) urlToFileSrc(s3File string) (*BulkFileSource, error) {
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

func (r *reProcess) Queue(s3Files ...string) ([]*BulkFileSource, error) {
	defer panicRecover(r.log, "Queue: %v", s3Files)
	var (
		urlLen = int64(len(s3Files))
		oks    = make([]string, 0, urlLen)
		es     = make([]error, 0)
		res    = make([]*BulkFileSource, 0, urlLen)
	)
	for _, url := range s3Files {
		if f, e := r.urlToFileSrc(url); e != nil {
			es = append(es, r.log.IfWarnF(e, "Queue: %v", url))
		} else {
			if e = r.kafka.Publish(r.kTopic, f, []byte(f.DeviceId)); e != nil {
				es = append(es, e)
			} else {
				res = append(res, f)
				oks = append(oks, url)
				r.log.Debug("Queue: '%v' OK for %v files", r.kTopic, url)
			}
		}
	}
	if len(res) == 0 {
		res = nil
	}
	return res, wrapErrors(es)
}

const (
	REPROC_KEY_OK  = "reProc:stats:ok"
	REPROC_KEY_ERR = "reProc:stats:err"
)

func (r *reProcess) flushStats() {
	defer panicRecover(r.log, "flushStats")

	if success := atomic.SwapInt64(&r.success, 0); success > 0 {
		if e := r.redis._client.IncrBy(REPROC_KEY_OK, success).Err(); e != nil {
			r.log.IfErrorF(e, "flushStats: %v", REPROC_KEY_OK)
			atomic.AddInt64(&r.success, success) //add it back!
		}
	}
	if errors := atomic.SwapInt64(&r.errors, 0); errors > 0 {
		if e := r.redis._client.IncrBy(REPROC_KEY_ERR, errors).Err(); e != nil {
			r.log.IfErrorF(e, "flushStats: %v", REPROC_KEY_ERR)
			atomic.AddInt64(&r.errors, errors) //add back
		}
	}
}

func (r *reProcess) ClearStats() error {
	es := make([]error, 0)
	_, e := r.redis.Delete(REPROC_KEY_OK)
	es = append(es, r.log.IfErrorF(e, "ClearStats: %v", REPROC_KEY_OK))
	_, e = r.redis.Delete(REPROC_KEY_ERR)
	es = append(es, r.log.IfErrorF(e, "ClearStats: %v", REPROC_KEY_ERR))
	return wrapErrors(es)
}

type ReProcessStats struct {
	FileQueue int `json:"fileQueue"`
	PathQueue int `json:"pathQueue"`
	Success   int `json:"success"`
	Error     int `json:"errors"`
}

func (r *reProcess) GetStats() (*ReProcessStats, error) {
	var (
		es  = make([]error, 0)
		res = ReProcessStats{}
	)
	if oks, e := r.redis.Get(REPROC_KEY_OK); e != nil && e != redis.Nil {
		es = append(es, r.log.IfErrorF(e, "GetStats: %v", REPROC_KEY_OK))
	} else {
		res.Success, _ = strconv.Atoi(oks)
	}
	if errors, e := r.redis.Get(REPROC_KEY_ERR); e != nil && e != redis.Nil {
		es = append(es, r.log.IfErrorF(e, "GetStats: %v", REPROC_KEY_ERR))
	} else {
		res.Error, _ = strconv.Atoi(errors)
	}
	res.FileQueue = r.kafka.Producer.Len()
	return &res, wrapErrors(es)
}
