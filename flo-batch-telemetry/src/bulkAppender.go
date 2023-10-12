package main

import (
	"errors"
	"fmt"
	"math"
	path2 "path"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

const (
	ENVVAR_CONCAT_S3_BUCKET_LF = "FLO_S3_BUCKET_TELEMETRY_APPEND"
	ENVVAR_CONCAT_S3_BUCKET_HF = "FLO_S3_BUCKET_TELEMETRY_APPEND_HF"
	ENVVAR_CONCAT_MAX_BATCH    = "FLO_CONCAT_MAX_BATCH"
	ENVVAR_CONCAT_MAX_WAIT     = "FLO_CONCAT_MAX_WAIT"
	ENVVAR_CONCAT_MAX_ROWS     = "FLO_CONCAT_MAX_ROWS"
	CONCAT_PATH                = `/tmp/concat`
)

var (
	CONCAT_S3_BUCKET_LF          string
	CONCAT_S3_BUCKET_HF          string
	CONCAT_MAX_BATCH             int32 = 100
	CONCAT_MAX_ROWS              int32
	CONCAT_MAX_WAIT_MIN          float64 = 5
	CONCAT_REDIS_KEY                     = `telemetry:append`
	CONCAT_REDIS_KEY_IN_PROGRESS         = ""
	CONCAT_REDIS_REM_BATCH               = 50
)

func init() {
	CONCAT_S3_BUCKET_LF = strings.TrimSpace(getEnvOrDefault(ENVVAR_CONCAT_S3_BUCKET_LF, ""))
	CONCAT_S3_BUCKET_HF = strings.TrimSpace(getEnvOrDefault(ENVVAR_CONCAT_S3_BUCKET_HF, ""))
	if m, e := strconv.Atoi(getEnvOrDefault(ENVVAR_CONCAT_MAX_BATCH, "")); e == nil && m > 0 {
		CONCAT_MAX_BATCH = int32(m)
	}
	if n, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_CONCAT_MAX_ROWS, "")); n < int(CONCAT_MAX_BATCH)*100 {
		CONCAT_MAX_ROWS = CONCAT_MAX_BATCH * 60 * 60 * 10
	} else {
		CONCAT_MAX_ROWS = int32(n)
	}
	if w, e := strconv.ParseFloat(getEnvOrDefault(ENVVAR_CONCAT_MAX_WAIT, ""), 64); e == nil && w > 0 {
		CONCAT_MAX_WAIT_MIN = w
	}
	//if _log.isDebug {
	//	CONCAT_REDIS_KEY += ":test"
	//}
	CONCAT_REDIS_KEY_IN_PROGRESS = CONCAT_REDIS_KEY + ":in-prog"
	CONCAT_RECOVER_MAX_WAIT_MIN = CONCAT_MAX_WAIT_MIN * 2

	_log.Notice("%v=%v %v=%v",
		ENVVAR_CONCAT_S3_BUCKET_HF, CONCAT_S3_BUCKET_HF,
		ENVVAR_CONCAT_S3_BUCKET_LF, CONCAT_S3_BUCKET_LF)
	if CONCAT_S3_BUCKET_HF == "" {
		_log.Warn("%v is empty, HF appender is disabled", ENVVAR_CONCAT_S3_BUCKET_HF)
	}
	if CONCAT_S3_BUCKET_LF == "" {
		_log.Warn("%v is empty, LF appender is disabled", ENVVAR_CONCAT_S3_BUCKET_LF)
	}
	_log.Notice("%v=%v", ENVVAR_CONCAT_MAX_BATCH, CONCAT_MAX_BATCH)
	_log.Notice("%v=%v", ENVVAR_CONCAT_MAX_WAIT, CONCAT_MAX_WAIT_MIN)
	_log.Notice("%v=%v", ENVVAR_CONCAT_MAX_ROWS, CONCAT_MAX_ROWS)

	rm, _ := strconv.Atoi(getEnvOrDefault("FLO_CONCAT_REDIS_REM_BATCH", "20"))
	if rm < 5 {
		rm = 5 //abs min batch size
	}
	_log.Notice("FLO_CONCAT_REDIS_REM_BATCH=%v", CONCAT_REDIS_REM_BATCH)
}

var (
	_permissionCheck int32 = 0
	_appenders             = sync.Map{}
)

func conCatPathPermissionCheck(l *Logger) {
	if atomic.CompareAndSwapInt32(&_permissionCheck, 0, 1) { //check once
		if e := ensureDirPermissionOK(CONCAT_PATH); e != nil {
			l.Fatal("full permission required @ %v", CONCAT_PATH)
			signalExit()
		}
	}
}

type IDisposable interface {
	Schedule(killSig *int32)
	Dispose()
}

type bulkAppender struct {
	redis    *RedisConnection
	s3Sess   *session.Session
	s3Bucket string
	log      *Logger
	lastUp   *int64
	mux      *sync.RWMutex
	csvGz    *gzFileWriter
}

func CreateBulkAppender(
	redis *RedisConnection,
	s3Sess *session.Session,
	s3Bucket string,
	log *Logger,
) *bulkAppender {

	l := log.CloneAsChild("appndr")
	if s3Bucket == "" {
		l.Debug("s3Bucket is EMPTY!")
		return nil
	} else if strings.EqualFold(getEnvOrDefault("FLO_DISABLE_BG_BULK", ""), "true") {
		l.Debug("FLO_DISABLE_BG_BULK is TRUE!")
		return nil
	}

	conCatPathPermissionCheck(l)
	app := &bulkAppender{
		redis:    redis,
		s3Sess:   s3Sess,
		s3Bucket: s3Bucket,
	}
	if b, ok := _appenders.LoadOrStore(s3Bucket, app); ok { //ensure singleton per bucket name
		app = b.(*bulkAppender) //swap loaded ref
		app.log = l
	} else {
		app.mux = &sync.RWMutex{} //so we don't create & dispose too many of these needlessly
		app.log = l
	}
	return app.config(l)
}

func (b *bulkAppender) config(l *Logger) *bulkAppender {
	if b == nil {
		return nil
	}
	if b.lastUp == nil || *b.lastUp == 0 {
		ut := time.Now().Unix()
		if _log.isDebug {
			ut -= int64(CONCAT_MAX_WAIT_MIN * 60) //will start ASAP
		} else {
			ut -= int64(CONCAT_MAX_WAIT_MIN*60) + (60 * 3) //will start in 3min
		}
		b.lastUp = &ut
	}
	b.ensureCsvGzAvailable(false)
	return b
}

func (b *bulkAppender) Dispose() {
	if b == nil {
		return
	}
	b.log.Debug("Dispose: %v begin", b.s3Bucket)
	defer b.log.Info("Dispose: %v completed", b.s3Bucket)
	if b.csvGz != nil {
		if b.mux != nil {
			b.mux.Lock()
			defer b.mux.Unlock()
		}
		b.csvGz.Dispose()
	}
}

func (b *bulkAppender) canScheduleFlush() (lastRun int64, ok bool) {
	defer panicRecover(b.log, "canScheduleFlush")
	b.log.PushScope("canFlush")
	defer b.log.PopScope()
	b.mux.RLock()
	defer b.mux.RUnlock()

	lastRun = atomic.LoadInt64(b.lastUp)
	now := time.Now().UTC().Unix()
	if dd := time.Duration(now-lastRun) * time.Second; dd.Minutes() >= CONCAT_MAX_WAIT_MIN {
		if b.csvGz.AppendFilesCount() != 0 {
			return lastRun, true
		}
	}
	return 0, false
}

func (b *bulkAppender) Schedule(cancelSignal *int32) { //periodically pull
	if b == nil {
		return
	}
	b.log.PushScope("sched")
	defer b.log.PopScope()

	b.log.Info("starting for %v", b.s3Bucket)
	defer b.log.Info("exiting")
	for atomic.LoadInt32(cancelSignal) == 0 {
		if lastRun, ok := b.canScheduleFlush(); ok {
			lastDt := time.Unix(lastRun, 0)
			b.log.Info("FLUSHING (%p) lastRun was @ %v, %v ago", b.csvGz, lastDt.UTC().Format(time.RFC3339), fmtDuration(time.Since(lastDt)))
			b.Flush(false)
		}
		time.Sleep(time.Second * 2)
	}
}

func deviceShardKey(mac string) string {
	if al := len(mac); al > 1 {
		return mac[al-1:]
	} else {
		return mac
	}
}

func (b *bulkAppender) canStore(meta *BulkFileSource, entryLen int32) (e error) {
	//b.log.PushScope("check")
	//defer b.log.PopScope()

	if meta == nil || entryLen == 0 {
		e = errors.New(b.log.Debug("meta is nil or entries are empty | %v", meta))
		return e
	}
	var (
		redisKey = unEscapeUrlPath(meta.SourceUri)
		dt       = meta.DateBucket()
		shardKey = deviceShardKey(meta.DeviceId)
	)
	return b.zKeyAdd(shardKey, redisKey, dt.Unix())
}

func (b *bulkAppender) zKeyAdd(shard, name string, dtUx int64) error {
	//b.log.PushScope("zKeyAdd", name, dtUx)
	//defer b.log.PopScope()
	if name == "" {
		return errors.New(b.log.Debug("can't bc name is blank"))
	}
	if dt := time.Unix(dtUx, 0); dt.Year() < 2000 {
		return errors.New(b.log.Debug("invalid dtUx value %v", dt.Format(time.RFC3339)))
	}

	if ok, reason := b.InProgressCheck(name); !ok {
		return errors.New(reason)
	}
	//_fetchFileSemaphore.Acquire(_bulkCtx, 1)
	//defer _fetchFileSemaphore.Release(1)

	var (
		zs  = redis.Z{Score: float64(dtUx), Member: name}
		key = fmt.Sprintf("%v:{%v}", CONCAT_REDIS_KEY, strings.ToLower(shard))
		cmd = b.redis._client.ZAdd(key, zs)
	)
	if n, e := cmd.Result(); e != nil { //check to see if another process picked up the file
		return b.log.IfErrorF(e, "%v @Z %v", name, CONCAT_REDIS_KEY)
	} else if n != 1 {
		return errors.New(b.log.Debug("another process already picked up %v @Z %v", name, CONCAT_REDIS_KEY))
	}
	return nil
}

func (b *bulkAppender) InProgressCheck(name string) (ok bool, reason string) {
	b.log.PushScope("progChk")
	defer b.log.PopScope()

	ks := fmt.Sprintf("%v:%v", CONCAT_REDIS_KEY_IN_PROGRESS, strings.ToLower(name))
	//_fetchFileSemaphore.Acquire(_bulkCtx, 1)
	//defer _fetchFileSemaphore.Release(1)

	if b.log.isDebug {
		return true, "debug allow"
	}
	exp := int(CONCAT_MAX_WAIT_MIN * 60) //takes about 5min to clean maybe
	if ok, _ = b.redis.SetNX(ks, time.Now().UTC().Unix(), exp); ok {
		return true, ""
	}
	return false, b.log.Trace("another process is already working on %v", ks)
}

func (b *bulkAppender) ensureCsvGzAvailable(noLock bool) (e error) {
	if b.csvGz == nil || b.csvGz.State() != 0 { //double check lock, the first one is cheap to check
		if !noLock {
			b.mux.Lock()
			defer b.mux.Unlock()
		}
		if noLock || b.csvGz == nil || b.csvGz.State() != 0 {
			b.csvGz.Dispose()
			if newCsvGz, e := RandomCsvGzFile(CONCAT_PATH, b.s3Bucket, _log.Clone().SetName("appdr")); e != nil {
				return b.log.Error("attempt to create csvGz failed for %v", b.s3Bucket)
			} else if newCsvGz != nil {
				b.csvGz = newCsvGz
				b.log.Debug("ensureCsvGzAvailable: noLock=%v (%p) for %v", noLock, b.csvGz, b.s3Bucket)
			}
		}
	}
	return e
}

func (b *bulkAppender) Flush(noLock bool) (e error) {
	started := time.Now()
	if b == nil {
		return errors.New("source binding is nil")
	}
	defer panicRecover(b.log, "Flush")
	b.log.PushScope("flush", b.csvGz.Name())
	defer b.log.PopScope()
	if !noLock {
		b.mux.Lock()
		defer b.mux.Unlock()
	}

	if st := b.csvGz.State(); st != 0 {
		return b.log.Warn("can't, wrong gz state %v", st)
	} else if b.csvGz.AppendFilesCount() == 0 {
		b.csvGz.Dispose()
		return errors.New(b.log.Debug("nothing to flush"))
	}
	atomic.StoreInt64(b.lastUp, started.UTC().Unix()) //set last flush time

	var (
		newKey = started.UTC().Truncate(time.Hour).Format("2006/01/02/15/") + path2.Base(b.csvGz.Name())
		rmKeys = b.csvGz.AppendKeys()
		files  = len(rmKeys)
		rows   = b.csvGz.AppendRowsCount()
		oldPtr = fmt.Sprintf("%p", b.csvGz)
	)
	defer b.ensureCsvGzAvailable(true)
	if e = b.sendToS3(b.csvGz, newKey); e == nil { //flush to s3
		b.zGroupRm(rmKeys...)
		b.log.Notice("%vms flushed %v files, %v rows -> (%v) s3://%v/%v",
			time.Since(started).Milliseconds(), files, rows, oldPtr, b.s3Bucket, newKey)
	}
	b.log.Trace("exit gzPtr (%p) for %v", b.csvGz, b.s3Bucket)
	return e
}

// StoreCsv append csv entries into an existing local csv.gz file, create one if not exists or flush if it's full after
// SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-2949
// SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-3197
func (b *bulkAppender) StoreCsv(dupCheck bool, meta *BulkFileSource, entries interface{}, entryLen int32) (e error) {
	started := time.Now()
	if b == nil {
		return errors.New("nil source binding: bulkAppender.StoreCsv(...)")
	} else if meta == nil || entryLen == 0 {
		return b.log.Warn("invalid inputs")
	}
	defer panicRecover(b.log, "StoreCsv: %v", meta.SourceUri)
	b.log.PushScope("StoreCsv")
	defer b.log.PopScope()

	if dupCheck {
		if e = b.canStore(meta, entryLen); e != nil {
			return e
		}
	}
	b.mux.Lock() //ensure concurrency from flush
	defer b.mux.Unlock()

	var rows int32
	path := b.csvGz.Path()
	if e = b.ensureCsvGzAvailable(true); e != nil {
		//just return, a warning already print
	} else if rows, e = b.csvGz.AppendCsv(meta, entries, entryLen); e != nil { //append error
		b.log.IfWarnF(e, "append failed for (%p) %v | %v rows", b.csvGz, path, entryLen)
	} else if b.csvGz.AppendFilesCount() >= CONCAT_MAX_BATCH || b.csvGz.AppendRowsCount() >= CONCAT_MAX_ROWS { //append ok, flush now
		e = b.Flush(true) //lockless flush bc we already have a lock here
	} else {
		b.log.Debug("%vms appended %v rows -> (%p) %v | %v", time.Since(started).Milliseconds(), rows, b.csvGz, path, path2.Base(meta.SourceUri))
	}
	return e
}

func (b *bulkAppender) zGroupRm(names ...string) error {
	b.log.PushScope("zGrp")
	defer b.log.PopScope()

	if nl := len(names); nl == 0 {
		return nil
	}
	var (
		shards = make(map[string][]string)
		sh     string
	)
	for _, n := range names {
		_, _, did := rebuildBulkFileSourceRaw(n)
		sh = deviceShardKey(did)

		if arr, found := shards[sh]; found {
			shards[sh] = append(arr, n)
		} else {
			shards[sh] = []string{n}
		}
	}
	es := make([]error, 0)
	for k, arr := range shards {
		if e := b.zKeyRm(k, arr); e != nil {
			es = append(es, e)
		}
	}
	return wrapErrors(es)
}

func (b *bulkAppender) zKeyRm(shard string, names []string) error {
	b.log.PushScope("zRem", shard)
	defer b.log.PopScope()
	if len(names) == 0 {
		return errors.New(b.log.Debug("can't, names are empty"))
	}

	var (
		batchSize    = CONCAT_REDIS_REM_BATCH
		namesLen     = len(names)
		totalBatches = int(math.Ceil(float64(namesLen) / float64(batchSize)))
		es           = make([]error, 0)
		shardKey     = fmt.Sprintf("%v:{%v}", CONCAT_REDIS_KEY, strings.ToLower(shard))
		remCount     = 0
	)
	//_fetchFileSemaphore.Acquire(_bulkCtx, 1)
	//defer _fetchFileSemaphore.Release(1)

	for i := 0; i < totalBatches; i++ {
		endIx := (i + 1) * batchSize
		if endIx > namesLen {
			endIx = namesLen
		}

		view := names[i*batchSize : endIx]
		vl := len(view)
		batch := make([]interface{}, vl)
		for j := 0; j < vl; j++ {
			batch[j] = view[j]
		}
		cmd := b.redis._client.ZRem(shardKey, batch...)
		if n, e := cmd.Result(); e != nil {
			es = append(es, b.log.IfWarnF(e, "can't remove @Z %v", shardKey))
		} else {
			remCount += int(n)
		}
	}
	b.log.Debug("evict %v -> names=%v, removed=%v", shardKey, namesLen, remCount)
	return wrapErrors(es)
}

//will also close & remove gz
func (b *bulkAppender) sendToS3(gz *gzFileWriter, newKey string) error {
	if gz == nil || gz.state != 0 {
		return errors.New(b.log.Info("sendToS3: gz (%p) is nil or has already been flushed", gz))
	}
	defer gz.Dispose()
	b.log.PushScope("sndS3", gz.Name())
	defer b.log.PopScope()

	gz.mux.Lock() //ensure nothing else writes to this file while we're trying to read
	defer gz.mux.Unlock()
	if e := gz.gzw.Close(); e != nil {
		return e
	}
	_, err := gz.file.Seek(0, 0)
	if err != nil {
		return b.log.IfErrorF(err, "can't seek")
	}

	req := s3.PutObjectInput{
		Bucket:      aws.String(b.s3Bucket),
		Key:         aws.String(newKey),
		ACL:         aws.String("private"),
		Body:        gz.file,
		ContentType: aws.String("application/x-gzip"),
	}
	_, err = s3.New(b.s3Sess).PutObject(&req)
	return b.log.IfErrorF(err, "can't upload (%p) %v -> s3://%v/%v", gz, gz.Path(), b.s3Bucket, newKey)
}
