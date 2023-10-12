package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/google/subcommands"
)

const APP_NAME = "water-meter"
const ENVVAR_HTTP_PORT = "FLO_HTTP_PORT"
const ENVVAR_REDIS_CN = "FLO_REDIS_CN"
const ENVVAR_PRESENCE_HOST = "FLO_PRESENCE_HOST"
const ENVVAR_KAFKA_CN = "FLO_KAFKA_CN"
const ENVVAR_DISABLE_BG_SERVICES = "FLO_DISABLE_BG_SERVICES"
const ENVVAR_KAFKA_GROUP_ID = "FLO_KAFKA_GROUP_ID"

var _cache *RedisConnection
var commitName string
var commitSha string
var commitTime string
var redisCn string
var presenceHost string
var kafkaCn string
var kafkaGroupId string
var disableBGServices string
var kafkaSystemModeTopic string
var cancel int32
var _hostName string
var _allow *allowList //allow only specific device id or mac address from Kafka for local debug
var _report WaterReport
var _noWrite bool //stop permanent write to environment data or db that could mess with a production system (meant for local debugging)

func main() {

	args := os.Args[1:]
	if len(args) > 0 {
		subcommands.Register(subcommands.HelpCommand(), "")
		subcommands.Register(subcommands.CommandsCommand(), "")
		subcommands.Register(&archiveCmd{}, "")

		flag.Parse()
		ctx := context.Background()
		os.Exit(int(subcommands.Execute(ctx)))
	}

	logInfo("Process: Starting...")
	httpPortString := getEnvOrExit(ENVVAR_HTTP_PORT)
	redisCn = getEnvOrExit(ENVVAR_REDIS_CN)
	presenceHost = getEnvOrExit(ENVVAR_PRESENCE_HOST)
	kafkaCn = getEnvOrExit(ENVVAR_KAFKA_CN)
	kafkaGroupId = getEnvOrExit(ENVVAR_KAFKA_GROUP_ID)
	disableBGServices = getEnvOrDefault(ENVVAR_DISABLE_BG_SERVICES, "false")
	if _noWrite = strings.EqualFold(getEnvOrDefault("FLO_NO_WRITE", ""), "true"); _noWrite {
		_log.Warn("!!!! FLO_NO_WRITE=true !!!!")
	} else {
		_log.Info("FLO_NO_WRITE=false")
	}

	_hostName = getHostname()
	cache, err := CreateRedisConnection(redisCn)
	if err != nil {
		log.Fatal("unable to connect to redis")
		os.Exit(-1)
	}
	_cache = cache
	_allow = CreateAllowList("FLO_ALLOW_RESTRICT", _log)

	portInt, err := strconv.ParseInt(httpPortString, 10, 32)
	if err != nil {
		logError("Unable to connect to parse http port. %v", err.Error())
		os.Exit(-11)
	}
	if portInt <= 0 || portInt > 65535 {
		logError("HTTP port range is invalid: %v", portInt)
		os.Exit(-11)
	}
	logNotice("Process: Started")

	tsReader := DefaultWaterReader().MustOpen() //pull TSDB data for redis write
	_report = CreateWaterReport(_log, CreateWaterCacheReader(_log, cache, tsReader))
	s3Reader := MustCreateDefaultGrafanaS3Reader()          //pull raw data from s3 for grafana
	tsGraRdr, err := CreateGrafanaTimeScaleReader(tsReader) //re-use pg to pull data for grafana
	if err != nil {
		os.Exit(10)
	}
	latestCache := DefaultLatestCacher(cache) //logic to store last telemetry per device for fast pull from redis
	kafTsPull := DefaultWaterConsumer()       //write water data from Kafka topic (pub by batch-telemetry) to TSDB
	setupRoutes(tsReader, kafTsPull, CreateGrafanaWebHandler(s3Reader, tsGraRdr))
	tsAggSch := NewWaterAggScheduler(_cache, kafTsPull.writer, _log)
	var schedule *Scheduler
	if !strings.EqualFold(disableBGServices, "true") {
		kafTsPull.MustStart() //receive kafka event & write to TS
		if latestCache != nil {
			latestCache.Open()
		}
		go presenceWorker()
		go deviceActivityWorker()
		tsAggSch.Open()

		tasks, e := setupTasks(cache, tsReader, CreateWaterCacheWriter(cache, _log))
		if e != nil {
			logFatal("Tasks did not start: %v", e)
			os.Exit(10)
		}
		schedule = CreateScheduler(tasks, cache, _log)
		schedule.Open()
	} else {
		logNotice("Background Services not started. %v set to %v", ENVVAR_DISABLE_BG_SERVICES, disableBGServices)
	}
	startWeb(int(portInt))

	// Wait for end signal, we'll accept graceful shutdowns when quit via SIGINT (Ctrl+C) or SIGTERM, SIGKILL, SIGQUIT
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL)

	// Block until we receive our signal.
	<-c
	logInfo("Process: Stopping...")

	// Increment cancel int to be greater than 0
	atomic.AddInt32(&cancel, 1)
	if schedule != nil {
		schedule.Close()
		logTrace("sched.Close() OK")
	}
	kafTsPull.Stop()
	logTrace("kafTsWriter.Stop() OK")
	tsReader.Close()
	logTrace("tsReader.Close() OK")
	if latestCache != nil {
		latestCache.Dispose()
		logTrace("latestCache.Dispose() OK")
	}
	stopWeb()
	logTrace("stopWeb() OK")
	tsAggSch.Close()
	s3Reader.Close()
	logTrace("s3Reader.Close() OK")
	tsGraRdr.Close()
	logTrace("tsGraRdr.Close() OK")

	time.Sleep(time.Second * 5)
	logNotice("Process: Stopped")
	os.Exit(0)
}

// Vincent - 606405c074ba
// Michael Lin - 606405bee6fc
