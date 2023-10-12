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

	"github.com/go-redis/redis"

	aw "github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"golang.org/x/sync/semaphore"
)

const (
	ENVVAR_REBULK_PATH_KEY      = "FLO_REBULK_PATH_KEY"
	ENVVAR_REBULK_PATH_BATCH    = "FLO_REBULK_PATH_BATCH"
	ENVVAR_REBULK_PATH_THREADS  = "FLO_REBULK_PATH_THREADS"
	ENVVAR_REBULK_PATH_SLEEP_MS = "FLO_REBULK_PATH_SLEEP_MS"
	ENVVAR_REPROCESS_PATH_KEY   = "FLO_REPROCESS_PATH_KEY"
)

type reProcessPath struct {
	queueKey string
	redis    *RedisConnection
	log      *Logger
	sem      *semaphore.Weighted //how many operations concurrently
	ctx      context.Context
	state    int32                 //0 == closed, 1 == open
	threads  int32                 //how many workers
	queueFn  func(...string) error //method to queue s3 files
	awsSess  *aw.Session
	s3Meta   *s3.S3
	batch    int32
	sleepMs  int32
}

func CreateReProcessPath(queueName string, s3Sess *aw.Session, redis *RedisConnection, log *Logger, queueFn func(...string) error) *reProcessPath {
	r := reProcessPath{
		queueKey: queueName,
		redis:    redis,
		log:      log.Clone().SetName("rePath").PushScope(queueName),
		queueFn:  queueFn,
		awsSess:  s3Sess,
		s3Meta:   s3.New(s3Sess),
		ctx:      context.Background(),
	}
	if r.log.isDebug {
		r.queueKey = r.queueKey + "_"
	}
	if n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_REBULK_PATH_THREADS, "1")); e == nil && n >= 0 {
		r.threads = int32(n)
	} else {
		r.threads = 1
	}
	r.sem = semaphore.NewWeighted(int64(r.threads) * 2)
	if n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_REBULK_PATH_BATCH, "")); e == nil && n > 0 {
		r.batch = int32(n)
	} else {
		r.batch = 1000
	}
	if n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_REBULK_PATH_SLEEP_MS, "20")); e == nil && n >= 0 {
		r.sleepMs = int32(n)
	} else {
		r.sleepMs = 20
	}
	r.log.Notice("queueName = %v", r.queueKey)
	r.log.Notice("%v=%v", ENVVAR_REBULK_PATH_BATCH, r.batch)
	r.log.Notice("%v=%v", ENVVAR_REBULK_PATH_THREADS, r.threads)
	r.log.Notice("%v=%v", ENVVAR_REBULK_PATH_SLEEP_MS, r.sleepMs)
	if r.threads == 0 {
		r.log.Warn("logic is DISABLED")
	}
	return &r
}

func (r *reProcessPath) Open() {
	if atomic.CompareAndSwapInt32(&r.state, 0, 1) {
		r.log.Info("Opening")
		for i := 0; i < int(r.threads); i++ {
			go r.worker(fmt.Sprintf("%p_%v", r.worker, i))
			time.Sleep(time.Millisecond * 777)
		}
		r.log.Notice("Opened")
	}
}

func (r *reProcessPath) Close() {
	if atomic.CompareAndSwapInt32(&r.state, 1, 0) {
		r.log.Notice("Closed")
	}
}

func (r *reProcessPath) worker(threadName string) {
	r.log.Notice("worker[%v]: Started", threadName)
	defer r.log.Notice("worker[%v]: Ended", threadName)

	for r != nil && atomic.LoadInt32(&r.state) == 1 {
		cmd := r.redis._client.RPop(r.queueKey)
		if js, e := cmd.Bytes(); e != nil {
			if e.Error() != "redis: nil" {
				r.log.IfErrorF(e, "worker[%v]: key %v | %v", threadName, r.queueKey, e.Error())
				time.Sleep(time.Second * 7) //back off
			} else {
				time.Sleep(time.Second * 4) //back off a little on empty pop
			}
		} else if jl := len(js); jl < 10 || js[0] != '{' || js[jl-1] != '}' {
			r.log.Warn("worker[%v]: key %v | invalid json %s", threadName, r.queueKey, js)
		} else {
			if r.sleepMs > 0 {
				time.Sleep(time.Duration(r.sleepMs) * time.Millisecond)
			}
			r.sem.Acquire(r.ctx, 1) //ensure we don't exceed out concurrent limits
			go func(jBuf []byte) {
				defer r.sem.Release(1)
				r.process(jBuf)
			}(js)
		}
	}
}

func (r *reProcessPath) PingS3() error {
	var (
		bucket = getEnvOrDefault(ENVVAR_S3_TELEMETRY_BUCKET, "")
		scan   = S3PathScan{Path: "s3://" + bucket}
		input  = scan.ToCheckInput(1)
		_, e   = r.s3Meta.ListObjectsV2(input)
	)
	r.log.IfErrorF(e, "PingS3")
	return e
}

func (r *reProcessPath) samePath(a, b *string) bool {
	if an, bn := a == nil, b == nil; an && bn {
		return true
	} else if !an && !bn {
		var (
			aStr, bStr = *a, *b
		)
		if al := len(aStr); al > 1 && aStr[al-1] == '/' {
			aStr = aStr[:al-1]
		}
		if bl := len(bStr); bl > 1 && bStr[bl-1] == '/' {
			bStr = bStr[:bl-1]
		}
		return strings.EqualFold(aStr, bStr)
	} else {
		return false
	}
}

// continue to scan the tail of a marker until the end is reach, each child path found is then sent queued for further processing
func (r *reProcessPath) process(jBuf []byte) {
	defer panicRecover(r.log, "process: %s", jBuf)

	var (
		started = time.Now()
		scan    = S3PathScan{}
	)
	if e := json.Unmarshal(jBuf, &scan); e != nil {
		r.log.IfWarnF(e, "process: bad json %s", jBuf)
	} else if e = scan.Check(); e != nil {
		r.log.IfWarnF(e, "process: Check failed")
	} else if isTelemetryFile(scan.Path) {
		r.log.Trace("process: queue file %s", scan.Path)
		r.queueFn(scan.Path) //somehow it's a file, just send it to processing here
	} else {
		var (
			input = scan.ToCheckInput(r.batch)
			res   *s3.ListObjectsV2Output
			errs  = make([]error, 0)
		)
		if res, e = r.s3Meta.ListObjectsV2(input); e != nil {
			r.log.IfErrorF(e, "process: %v", scan)
		} else { //process path
			var (
				pathArr = make([]S3PathScan, 0)
				fileArr = make([]string, 0)
			)
			for _, m := range res.Contents { //should be files only
				mk := strPtr(m.Key)
				if mk == "" {
					continue
				}
				if bk := strPtr(input.Bucket); bk != "" {
					if size := int64Ptr(m.Size); size > 0 { //file of some sort
						if isTelemetryFile(mk) {
							uri := fmt.Sprintf("s3://%s/%s", bk, mk)
							fileArr = append(fileArr, uri)
						}
					} else if !r.samePath(m.Key, input.Prefix) { //this should never happens but just in-case
						uri := fmt.Sprintf("s3://%s/%s", bk, mk)
						pathArr = append(pathArr, S3PathScan{Path: uri}) //dive deeper into the children path
					}
				}
			}

			if boolPtr(res.IsTruncated) {
				if next := strPtr(res.NextContinuationToken); next != "" { //continue to tail current path
					pathArr = append(pathArr, S3PathScan{Path: scan.Path, StartKey: next})
				}
			}

			var (
				files = len(fileArr)
				paths = len(pathArr)
			)
			if files != 0 {
				if e = r.queueFn(fileArr...); e != nil {
					errs = append(errs, e)
				}
			}
			if paths != 0 {
				if e = r.Queue(pathArr...); e != nil {
					errs = append(errs, e)
				}
			}

			var ( //log results
				ll   = LL_DEBUG
				sb   = _loggerSbPool.Get()
				lArg = []interface{}{scan.Path, scan.StartKey, time.Since(started)}
			)
			defer _loggerSbPool.Put(sb)
			sb.WriteString("process: %s at %q | took %v | ")

			if paths == 0 && files == 0 {
				sb.WriteString("no_children")
			} else {
				ll = LL_INFO
				sb.WriteString("files=%v, paths=%v")
				lArg = append(lArg, files, paths)
			}
			if len(errs) != 0 {
				ll = LL_WARN
				sb.WriteString(" | with errors -> %v")
				lArg = append(lArg, wrapErrors(errs))
			}
			r.log.Log(ll, sb.String(), lArg...)
		}
	}
}

type S3PathScan struct {
	Path     string `json:"path"`
	StartKey string `json:"start"`
}

func (sc *S3PathScan) Check() error {
	if strings.Index(sc.Path, "s3://") != 0 {
		return errors.New("invalid s3 path: " + sc.Path)
	}
	return nil
}

func (sc *S3PathScan) ToCheckInput(batch int32) *s3.ListObjectsV2Input {
	const delimiter = "/"
	var (
		maxKeys = int64(batch)
		arr     = strings.Split(sc.Path[5:], delimiter)
		pre     = ""
	)
	if len(arr) > 1 {
		pre = strings.Join(arr[1:], delimiter)
	}
	p := s3.ListObjectsV2Input{
		Bucket:  &arr[0],
		Prefix:  &pre,
		MaxKeys: &maxKeys,
	}
	if sc.StartKey != "" {
		p.ContinuationToken = &sc.StartKey
	}
	return &p
}

const TELEMETRY_EXT_LEN = len(TELEMETRY_EXT)

func isTelemetryFile(path string) bool {
	pl := len(path)
	return strings.LastIndex(path, TELEMETRY_EXT) == pl-TELEMETRY_EXT_LEN
}

func (r *reProcessPath) QueuePaths(paths ...string) error {
	if pl := len(paths); pl == 0 {
		return r.log.Warn("QueuePaths: input is empty")
	} else {
		dirs := make([]S3PathScan, 0, pl)
		for _, p := range paths {
			if p != "" {
				dirs = append(dirs, S3PathScan{p, ""})
			}
		}
		if len(dirs) == 0 {
			return r.log.Warn("QueuePaths: input has no valid values")
		} else {
			return r.Queue(dirs...)
		}
	}
}

func (r *reProcessPath) Queue(dirs ...S3PathScan) error {
	defer panicRecover(r.log, "Queue: %v", dirs)
	var (
		urlLen = int64(len(dirs))
		arr    = make([]interface{}, 0, urlLen)
	)
	for _, arg := range dirs {
		if e := arg.Check(); e != nil {
			r.log.IfWarnF(e, "Queue:")
		} else if buf, e := json.Marshal(arg); e != nil {
			r.log.IfWarnF(e, "Queue: marshal err for %v", arg)
		} else {
			arr = append(arr, buf)
		}
	}
	if len(arr) == 0 {
		return r.log.Warn("Queue: unable to compile any input | %v", dirs)
	}

	cmd := r.redis._client.LPush(r.queueKey, arr...)
	if n, err := cmd.Result(); err != nil {
		return r.log.IfErrorF(err, "Queue: '%v' Failed %v | len=%v %v", r.queueKey, err.Error(), urlLen, dirs)
	} else {
		r.log.Debug("Queue: '%v' OK for %v files", r.queueKey, n)
		return nil
	}
}

func (r *reProcessPath) Size() int64 {
	cmd := r.redis._client.LLen(r.queueKey)
	if n, e := cmd.Result(); e != nil {
		r.log.IfErrorF(e, "Size: redis")
		return -1
	} else {
		return n
	}
}

func (r *reProcessPath) Truncate() (int64, error) {
	if n, e := r.redis.Delete(r.queueKey); e != nil && e != redis.Nil {
		return 0, r.log.IfWarnF(e, "Truncate: %v", r.queueKey)
	} else {
		r.log.Notice("Truncate: OK %v removed=%v", r.queueKey, n)
		return n, nil
	}
}
