package main

import (
	"os"
	"os/signal"
	"strconv"
	"sync/atomic"
	"syscall"
	"time"
)

const APP_NAME = "flo-device-heartbeat"
const ENVVAR_HTTP_PORT = "FLO_HTTP_PORT"
const ENVVAR_KAFKA_HOSTS = "FLO_KAFKA_CN"
const ENVVAR_KAFKA_GROUP_ID = "FLO_KAFKA_GROUP_ID"
const ENVVAR_PGDB_DEVICE = "FLO_PGDB_CN"
const ENVVAR_REDIS_DEVICE = "FLO_REDIS_CN"
const ENVVAR_FIREWRITER_HOST = "FLO_FIREWRITER_HOST"
const ENVVAR_NOTIFICATION_API_URL = "FLO_NOTIFICATION_API_URL"
const ENVVAR_DEVICE_SERVICE_URL = "FLO_DEVICE_SERVICE_URL"
const ENVVAR_FLO_TTL_DEVICE_FLO = "FLO_TTL_DEVICE_FLO"
const ENVVAR_FLO_TTL_PUCK_OEM = "FLO_TTL_PUCK_OEM"

var _commitSha string
var _commitTime string
var _cancel int32
var _hostName string
var kafkaHost string
var kafkaGroupId string
var pgConnectionString string
var _dbCn *PgSqlDb
var _fireWriterHost string
var _redisCn string
var _redis *RedisConnection
var _notificationAPIURL string
var _deviceServiceURL string
var floDeviceHeartbeatTTL float64
var floPuckOemHeartbeatTTL float64

func main() {
	logInfo("main: Starting...")

	_hostName = getHostname()
	kafkaHost = getEnvOrExit(ENVVAR_KAFKA_HOSTS)
	kafkaGroupId = getEnvOrExit(ENVVAR_KAFKA_GROUP_ID)
	httpPortString := getEnvOrExit(ENVVAR_HTTP_PORT)
	pgConnectionString = getEnvOrExit(ENVVAR_PGDB_DEVICE)
	_fireWriterHost = getEnvOrExit(ENVVAR_FIREWRITER_HOST)
	_redisCn = getEnvOrExit(ENVVAR_REDIS_DEVICE)
	_notificationAPIURL = getEnvOrDefault(ENVVAR_NOTIFICATION_API_URL, "https://flo-notification-api.flosecurecloud.com")
	_deviceServiceURL = getEnvOrDefault(ENVVAR_DEVICE_SERVICE_URL, "https://flo-device-service.flosecurecloud.com/v1")
	floDeviceHeartbeatTTLEnv := getEnvOrDefault(ENVVAR_FLO_TTL_DEVICE_FLO, "61")
	floPuckOemHeartbeatTTLEnv := getEnvOrDefault(ENVVAR_FLO_TTL_PUCK_OEM, "241")

	portInt, err := strconv.ParseInt(httpPortString, 10, 32)
	if err != nil {
		logError("main: Unable to connect to parse http port. %v", err.Error())
		os.Exit(11)
	}

	if portInt <= 0 || portInt > 65535 {
		logError("main: HTTP port range is invalid: %v", portInt)
		os.Exit(11)
	}

	_dbCn, err = OpenPgSqlDb(pgConnectionString)
	if err != nil {
		logError("main: Error connecting to DB: %v", err.Error())
		os.Exit(11)
	}

	_redis, err = OpenRedisConnection(_redisCn)
	if err != nil {
		logError("main: Error connecting to redis: %v", err.Error())
		os.Exit(11)
	}

	floDeviceHeartbeatTTL, err = strconv.ParseFloat(floDeviceHeartbeatTTLEnv, 64)
	if err != nil {
		logError("main: Invalid value for environment variable FLO_TTL_DEVICE_FLO. Malformed value: %v. %v", floDeviceHeartbeatTTLEnv, err.Error())
		os.Exit(11)
	}

	floPuckOemHeartbeatTTL, err = strconv.ParseFloat(floPuckOemHeartbeatTTLEnv, 64)
	if err != nil {
		logError("main: Invalid value for environment variable FLO_TTL_PUCK_OEM. Malformed value: %v. %v", floDeviceHeartbeatTTLEnv, err.Error())
		os.Exit(11)
	}

	logInfo("main: Started")
	logNotice("%v started on %v", APP_NAME, _hostName)

	startHeartBeat()
	startPresenceAlerts()
	startWeb(int(portInt))

	// Wait for end signal
	// We'll accept graceful shutdowns when quit via SIGINT (Ctrl+C) or SIGTERM
	// SIGKILL or SIGQUIT will not be caught.
	c := make(chan os.Signal, 2)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	// Block until we receive our signal.
	<-c

	logInfo("main: Stopping...")

	// Increment _cancel int to be greater than 0
	atomic.AddInt32(&_cancel, 1)

	stopWeb()

	time.Sleep(time.Second * 5)

	logInfo("main: Stopped")
	logNotice("%v stopped on %v", APP_NAME, _hostName)

	os.Exit(0)
}
