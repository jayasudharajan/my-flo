package main

import (
	"os"
	"os/signal"
	"strconv"
	"sync/atomic"
	"syscall"
	"time"
)

const APP_NAME = "flo-science-lab"
const HTTP_DEFAULT_PORT = "8080"
const ENVVAR_HTTP_PORT = "FLO_HTTP_PORT"
const ENVVAR_PGCN = "FLO_PGDB_CN"
const ENVVAR_API_TOKEN = "FLO_API_TOKEN"
const ENVVAR_API_URL = "FLO_API_URL"
const ENVVAR_DSS_API_URL = "FLO_DSS_API_URL"
const ENVVAR_KAFKA_CN = "FLO_KAFKA_CN"
const ENVVAR_KAFKA_GROUP_ID = "FLO_KAFKA_GROUP_ID"
const ENVVAR_MODEL_BUCKET_NAME = "FLO_MODEL_BUCKET_NAME"
const ENVVAR_MODEL_URL_PREFIX = "FLO_MODEL_URL_PREFIX"
const ENVVAR_REDIS_CN = "FLO_REDIS_CN"
const ENVVAR_FD_24_HR_CRON = "FLO_FD_24_HR_CRON"
const FD_24_HR_CRON_DEFAULT = "0 * * * *" // Every hour
const ENVVAR_FD_7_D_CRON = "FLO_FD_7_D_CRON"
const FD_7_D_CRON_DEFAULT = "*/30 * * * *" // Every half hour
const ENVVAR_FD_TRAIN_CRON = "FLO_FD_TRAIN_CRON"
const FD_TRAIN_CRON_DEFAULT = "0 0 * * *" // Every midnight
const ENVVAR_FD_SCAN_CRON = "FLO_FD_SCAN_CRON"
const FD_SCAN_CRON_DEFAULT = "0 0 * * *" // Every midnight
const ENVVAR_FD_24_HR_TOPIC = "FLO_FD_24_HR_TOPIC"
const FD_24_HR_TOPIC_DEFAULT = "fixture-detection-v1-24h"
const ENVVAR_FD_7_D_TOPIC = "FLO_FD_7_D_TOPIC"
const FD_7_D_TOPIC_DEFAULT = "fixture-detection-v1"
const ENVVAR_FD_TRAIN_TOPIC = "FLO_FD_TRAIN_TOPIC"
const FD_TRAIN_TOPIC_DEFAULT = "fixture-detection-trainer-v1"
const ENVVAR_PES_SCHEDULE_RETRY_CRON = "FLO_PES_SCHEDULE_RETRY_CRON"
const PES_SCHEDULE_RETRY_CRON_DEFAULT = "0 * * * *" // Every hour
const ENVVAR_PES_SCHEDULE_RETRY_BATCH_SIZE = "PES_SCHEDULE_RETRY_BATCH_SIZE"
const PES_SCHEDULE_RETRY_BATCH_SIZE_DEFAULT = "400"

var _commitSha string
var _commitTime string
var _cancel int32
var _hostName string
var _apiToken string
var _apiUrl string
var _dsApiUrl string
var _kafkaCn string
var _kafkaGroupId string
var _modelBucketName string
var _modelUrlPrefix string
var _floDetect24HrCron string
var _floDetect7DCron string
var _floDetectTrainCron string
var _floDetectPopulateCron string
var _floDetect24HrTopic string
var _floDetect7DTopic string
var _floDetectTrainTopic string
var _pesScheduleRetryCron string
var _pesScheduleRetryBatchSize int16
var _redisCn string
var _pgCn *PgSqlDb
var _s3 *S3Handler
var _redis *RedisConnection

// @title Science Lab Api
// @version 1.0
// @description Handles FloSense and PES features
// @host flo-science-lab.flosecurecloud.com flo-science-lab.flocloud.co
// @schemes https http
func main() {
	logInfo("main: Starting...")

	_hostName = getHostname()
	_apiToken = getEnvOrExit(ENVVAR_API_TOKEN)
	_apiUrl = getEnvOrExit(ENVVAR_API_URL)
	_dsApiUrl = getEnvOrExit(ENVVAR_DSS_API_URL)
	_kafkaCn = getEnvOrExit(ENVVAR_KAFKA_CN)
	_kafkaGroupId = getEnvOrExit(ENVVAR_KAFKA_GROUP_ID)
	_modelBucketName = getEnvOrExit(ENVVAR_MODEL_BUCKET_NAME)
	_modelUrlPrefix = getEnvOrExit(ENVVAR_MODEL_URL_PREFIX)
	_redisCn = getEnvOrExit(ENVVAR_REDIS_CN)
	pgCnString := getEnvOrExit(ENVVAR_PGCN)
	httpPortString := getEnvOrDefault(ENVVAR_HTTP_PORT, HTTP_DEFAULT_PORT)
	_floDetect24HrCron = getEnvOrDefault(ENVVAR_FD_24_HR_CRON, FD_24_HR_CRON_DEFAULT)
	_floDetect7DCron = getEnvOrDefault(ENVVAR_FD_7_D_CRON, FD_7_D_CRON_DEFAULT)
	_floDetectTrainCron = getEnvOrDefault(ENVVAR_FD_TRAIN_CRON, FD_TRAIN_CRON_DEFAULT)
	_floDetectPopulateCron = getEnvOrDefault(ENVVAR_FD_SCAN_CRON, FD_SCAN_CRON_DEFAULT)
	_floDetect24HrTopic = getEnvOrDefault(ENVVAR_FD_24_HR_TOPIC, FD_24_HR_TOPIC_DEFAULT)
	_floDetect7DTopic = getEnvOrDefault(ENVVAR_FD_7_D_TOPIC, FD_7_D_TOPIC_DEFAULT)
	_floDetectTrainTopic = getEnvOrDefault(ENVVAR_FD_TRAIN_TOPIC, FD_TRAIN_TOPIC_DEFAULT)
	_pesScheduleRetryCron = getEnvOrDefault(ENVVAR_PES_SCHEDULE_RETRY_CRON, PES_SCHEDULE_RETRY_CRON_DEFAULT)
	pesScheduleRetryBatchSizeInt64, err := strconv.ParseInt(getEnvOrDefault(ENVVAR_PES_SCHEDULE_RETRY_BATCH_SIZE, PES_SCHEDULE_RETRY_BATCH_SIZE_DEFAULT), 10, 16)
	if err != nil {
		logError("main: Unable to parse ENV VAR: PES_SCHEDULE_RETRY_BATCH_SIZE. %v", err.Error())
		os.Exit(5)
	}
	_pesScheduleRetryBatchSize = int16(pesScheduleRetryBatchSizeInt64)

	portInt, err := strconv.ParseInt(httpPortString, 10, 32)
	if err != nil {
		logError("main: Unable to connect to parse http port. %v", err.Error())
		os.Exit(5)
	}
	if portInt <= 0 || portInt > 65535 {
		logError("main: HTTP port range is invalid: %v", portInt)
		os.Exit(5)
	}

	s3tmp, err := InitAwsS3(_modelBucketName)
	if err != nil {
		logError("main: Unable to connect to AWS S3. %v", err.Error())
		os.Exit(5)
	}
	_s3 = s3tmp

	pg, err := OpenPgSqlDb(pgCnString)
	if err != nil {
		logError("main: unable to connect to database. %v", err.Error())
		os.Exit(10)
	}
	_pgCn = pg

	red, err := newRedisConnection(_redisCn)
	if err != nil {
		logError("main: unable to connect to redis. %v", err.Error())
		os.Exit(10)
	}
	_redis = red

	kafkaConn, err := OpenKafka(_kafkaCn)

	if err != nil {
		logError("main: unable to connect to kafka. %v", err.Error())
	}

	stopFloDetect, err := initFloDetectJobs(pg, kafkaConn, _redis)

	if err != nil {
		logError("main: unable to start FloDetect cron jobs. %v", err.Error())
		os.Exit(10)
	}

	initEntityActivity()
	initPesDirectiveWorker()
	initDevicePropertiesWorker()
	initFloSenseRetryWorker()
	stopPesScheduleRetryJob, err := initPesScheduleRetryJob()

	if err != nil {
		logError("main: unable to start FloScheduleRetry cron jobs. %v", err.Error())
		os.Exit(10)
	}

	logInfo("main: Started")
	logNotice("%v started", APP_NAME)

	startWeb(int(portInt))

	// Wait for end signal
	// We'll accept graceful shutdowns when quit via SIGINT (Ctrl+C) or SIGTERM
	// SIGKILL or SIGQUIT will not be caught.
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)

	// Block until we receive our signal.
	<-c

	logInfo("main: Stopping...")

	// Increment _cancel int to be greater than 0
	atomic.AddInt32(&_cancel, 1)

	stopWeb()
	stopFloDetect()
	stopPesScheduleRetryJob()

	time.Sleep(time.Second * 5)

	logInfo("main: Stopped")
	logNotice("%v stopped", APP_NAME)

	time.Sleep(time.Second)

	os.Exit(0)
}
