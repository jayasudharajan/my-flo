package main

import (
	"context"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

const APP_NAME = "flo-detect-v2"
const HTTP_DEFAULT_PORT = "8080"
const ENVVAR_HTTP_PORT = "FLO_HTTP_PORT"
const ENVVAR_PGCN = "FLO_PGDB_CN"
const ENVVAR_API_URL = "FLO_API_URL"
const ENVVAR_KAFKA_CN = "FLO_KAFKA_CN"
const ENVVAR_KAFKA_GROUP_ID = "FLO_KAFKA_GROUP_ID"
const ENVVAR_FIREWRITER_URL = "FLO_FIREWRITER_URL"
const KAFKA_TOPIC_FLODETECT_EVENT = "flodetect-event-v2"

var _commitSha string
var _commitTime string
var _hostName string
var _start time.Time
var _kafkaCn string
var _kafkaGroupId string
var _pgCnString string
var _httpPortString string
var _pgCn *PgSqlDb
var _kafka *KafkaConnection
var _apiUrl string
var _fireWriterUrl string

// @title FloDetect v2 Api
// @version 2.0
// @description FloDetect Api Documentation
// @schemes https http
func main() {
	logInfo("main: Starting...")

	ctx := context.Background()
	_start = time.Now()
	_hostName = getHostname()
	_kafkaCn = getEnvOrExit(ENVVAR_KAFKA_CN)
	_kafkaGroupId = getEnvOrExit(ENVVAR_KAFKA_GROUP_ID)
	_pgCnString = getEnvOrExit(ENVVAR_PGCN)
	_apiUrl = getEnvOrExit(ENVVAR_API_URL)
	_fireWriterUrl = getEnvOrExit(ENVVAR_FIREWRITER_URL)
	_httpPortString = getEnvOrDefault(ENVVAR_HTTP_PORT, HTTP_DEFAULT_PORT)

	startTracing()

	portInt, err := strconv.ParseInt(_httpPortString, 10, 32)
	if err != nil {
		logError("main: Unable to connect to parse http port. %v", err.Error())
		os.Exit(-11)
	}

	if portInt <= 0 || portInt > 65535 {
		logError("main: HTTP port range is invalid: %v", portInt)
		os.Exit(-11)
	}

	pg, err := OpenPgSqlDb(ctx, _pgCnString)
	if err != nil {
		logError("main: unable to connect to database. %v", err.Error())
		os.Exit(10)
	}
	_pgCn = pg

	kafkaCn, err := OpenKafka(ctx, _kafkaCn, nil)
	if err != nil {
		logError("main: unable to connect to kafka. %v", err.Error())
		os.Exit(10)
	}
	_kafka = kafkaCn

	// Background Processes
	if strings.EqualFold(getEnvOrDefault("FLO_DISABLE_WORKERS", ""), "true") {
		logNotice("FLO_DISABLE_WORKERS=true")
	} else {
		err = startFloDetectEventConsumer()
		if err != nil {
			logError("main: unable to start kafka consumer. %v", err.Error())
			os.Exit(20)
		}
		startListsWorker()
	}
	logInfo("main: Started")

	startWeb(int(portInt))

	// Wait for end signal
	// We'll accept graceful shutdowns when quit via SIGINT (Ctrl+C) or SIGTERM
	// SIGKILL or SIGQUIT will not be caught.
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)

	// Block until we receive our signal.
	<-c

	logInfo("main: Stopping...")

	stopWeb()
	_kafka.Close()

	logInfo("main: Stopped")

	os.Exit(0)
}

func startTracing() {
	tracing.StartTracing(_hostName)
}
