package main

import (
	"fmt"
	"os"
	"os/signal"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
)

const (
	APP_NAME                = "flo-batch-telemetry"
	ENVVAR_KAFKA_CN         = "FLO_KAFKA_CN"
	ENVVAR_KAFKA_GROUP      = "FLO_KAFKA_GROUP_ID"
	ENVVAR_SQS_BULK_NAME    = "FLO_SQS_NAME_BULK_FILE"
	ENVVAR_TELEMETRY_LATEST = "FLO_TELEMETRY_LATEST_TOPIC"
	ENVVAR_REDIS_CN         = "FLO_REDIS_CN"
)

var (
	_commitSha            string
	_commitTime           string
	_cancel               int32
	_hostName             string
	_kafkaCn              string
	_sqsNameBulkFile      string
	_kafkaGroupId         string
	_latestTelemetryTopic string
	_redis                *RedisConnection
	_session              *session.Session //aws session used for sqs & s3

	_reBulk       *reBulk
	_reBulkPath   *reProcessPath
	_reBulkBuffer *queueBuffer

	_reProc     *reProcess
	_reProcPath *reProcessPath
	_recover    *bulkRecover
	_mock       MockTelemetry

	_start             = time.Now()
	_osInterrupt       = make(chan os.Signal, 1)
	_initOnce    int32 = 0
)

func signalExit() {
	_osInterrupt <- syscall.SIGABRT
}

func initSingletons() {
	if !atomic.CompareAndSwapInt32(&_initOnce, 0, 1) {
		return //already init
	}
	_hostName = getHostname()
	_kafkaCn = getEnvOrExit(ENVVAR_KAFKA_CN)
	_kafkaGroupId = getEnvOrDefault(ENVVAR_KAFKA_GROUP, "flo-telemetry-tags-prod")
	_sqsNameBulkFile = getEnvOrExit(ENVVAR_SQS_BULK_NAME)
	_latestTelemetryTopic = getEnvOrExit(ENVVAR_TELEMETRY_LATEST)

	if red, err := NewRedisConnection(getEnvOrExit(ENVVAR_REDIS_CN)); err != nil {
		_log.Fatal("unable to connect to redis. %v", err.Error())
		signalExit()
	} else {
		_redis = red
	}

	if sess, err := session.NewSession(&aws.Config{Region: aws.String("us-west-2")}); err != nil {
		_log.Fatal("unable to create aws session. %v", err.Error())
		signalExit()
	} else {
		_session = sess //will be used by sqsReader & FileListening for bulk
	}

	initFileListener() //setup _kafkaFileTopic here

	_reBulk = CreateReBulk(_redis, _log)
	qFunc := _reBulk.Queue
	if _log.isDebug && strings.EqualFold(getEnvOrDefault("FLO_MOCK_QUEUE", ""), "true") {
		qFunc = func(s3Files ...string) error {
			_log.Debug("FLO_MOCK_QUEUE: %v", s3Files)
			return nil
		}
	}
	_reBulkBuffer = CreateQueueBuffer(qFunc, _log)
	_reBulkPath = CreateReProcessPath(
		getEnvOrDefault(ENVVAR_REBULK_PATH_KEY, "reBulk:path:q"),
		_session, _redis, _log, _reBulkBuffer.Queue)

	_reProc = CreateReProcess(_kafkaFileTopic, _redis, _log)
	_reProcPath = CreateReProcessPath(
		getEnvOrDefault(ENVVAR_REPROCESS_PATH_KEY, "reProc:path:q"),
		_session, _redis, _log, func(urls ...string) error {
			_, e := _reProc.Queue(urls...)
			return e
		})

	_mock = CreateMockTelemetry(_session, _redis, _kafkaCn, _log)
}

// @title flo-batch-telemetry Api
// @version 1.0
// @description flo-batch-telemetry Api Documentation
// @host flo-batch-telemetry.flosecurecloud.com gojumpstart.flocloud.co
// @schemes https http
func main() {
	_log.Notice("main: Starting...")
	signal.Notify(_osInterrupt, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
	initSingletons()

	union := organizeWorkers()
	if ws := CreateWebServer(_log, registerRoutes, union); ws != nil {
		time.Sleep(time.Second)
		ws.Open()
		sig, _ := <-_osInterrupt //will block until exit signal is received
		fmt.Println()

		_log.Notice("main: Stopping...")
		ws.Close()
		if sig == syscall.SIGABRT {
			_log.Fatal("main: Forced exit. Uptime was %v", fmtDuration(time.Since(_start)))
			os.Exit(30)
		} else {
			_log.Notice("main: Stopped. Uptime was %v", fmtDuration(time.Since(_start)))
			os.Exit(0)
		}
		return
	}

	atomic.AddInt32(&_cancel, 1)
	close(_osInterrupt)
	time.Sleep(time.Second * 5) //allow unknown cleanup to complete
	_log.Fatal("main: Crash")
	os.Exit(-11)
}

func organizeWorkers() []ICloser {
	union := []ICloser{
		&funcCloser{
			logger: _log,
			close: func() {
				atomic.AddInt32(&_cancel, 1) //signal program end
				if _kafkaSub != nil {        //stop inbound messages first
					_kafkaSub.Close()
				}
			},
		},
		_reProcPath,
		_reProc,
	}
	var (
		disableBulk = strings.EqualFold(getEnvOrDefault("FLO_DISABLE_BG_BULK", ""), "true")
		noRebulk    = strings.EqualFold(getEnvOrDefault("FLO_DISABLE_BG_REBULK", ""), "true")
	)
	if !(disableBulk || noRebulk) {
		union = append(union, _reBulkPath, _reBulkBuffer, _reBulk)
	} else {
		logWarn("REBULK PROCESSING DISABLED")
	}

	if !strings.EqualFold(getEnvOrDefault("FLO_DISABLE_BG_SQS", ""), "true") {
		union = append(union,
			&funcCloser{startSqsReader, _kafkaSqs.Close, _log},
		)
	} else {
		logWarn("FLO_DISABLE_BG_SQS=true")
	}
	if !strings.EqualFold(getEnvOrDefault("FLO_DISABLE_BG_FILE", ""), "true") {
		logDebug("FLO_DISABLE_BG_FILE=false adding startFileListener")
		union = append(union,
			&funcCloser{startFileListener, _kafkaFileTopic.Close, _log},
		)
	} else {
		logWarn("FLO_DISABLE_BG_FILE=true")
	}

	var ap1, ap2 = false, false
	if lfAppender := CreateBulkAppender(_redis, _session, CONCAT_S3_BUCKET_LF, _log.Clone()); lfAppender != nil {
		union = append(union, &disposableCloser{&_cancel, lfAppender, _log})
		ap1 = true
	} else {
		logWarn("BULK_APPENDER_LF DISABLED")
	}

	if hfAppender := CreateBulkAppender(_redis, _session, CONCAT_S3_BUCKET_HF, _log.Clone()); hfAppender != nil {
		union = append(union, &disposableCloser{&_cancel, hfAppender, _log})
		ap2 = true
	} else {
		logWarn("BULK_APPENDER_HF DISABLED")
	}

	_recover = CreateBulkRecover(_redis, _session, _log) //always init due to count function
	if ap1 && ap2 {
		if _recover != nil {
			union = append(union, &disposableCloser{&_cancel, _recover, _log})
		}
	} else {
		logWarn("REBULK RECOVERY DISABLED")
	}
	return union
}
