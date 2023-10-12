package main

import (
	"os"
	"strconv"

	"github.com/labstack/gommon/log"
)

const commitSHAKey = "COMMIT_SHA"
const commitNameKey = "COMMIT_NAME"
const buildDateKey = "BUILD_DATE"

const serviceNameKey = "SERVICE_NAME"
const envKey = "ENVIRONMENT"

const webServerPortKey = "LS_WEB_SERVER_PORT"

const logsLevelKey = "LOGS_LEVEL"

const dbNameKey = "LS_DB_NAME"
const dbHostKey = "LS_DB_HOST"
const dbPortKey = "LS_DB_PORT"
const dbUserKey = "LS_DB_USER"
const dbPasswordKey = "LS_DB_PASSWORD"
const dbMaxOpenConnectionsKey = "LS_DB_MAX_OPEN_CONNECTIONS"
const dbMaxIdleConnectionsKey = "LS_DB_MAX_IDLE_CONNECTIONS"
const fallbackLocaleKey = "FALLBACK_LOCALE"

const dbIngestionTimeIntervalKey = "DB_INGESTION_TIME_INTERVAL"

const DefaultServiceName = "flo-localization-service"
const DefaultEnv = "local"

const defaultWebServerPort = "3000"

// default logs level is set to 2 -> INFO
const defaultLogsLevel = "2"

const defaultDbHost = "localhost"
const defaultDbPort = "5432"
const defaultDbUser = "admin"
const defaultDbPassword = "12345"
const defaultDbName = "localization-service-db"
const defaultDbMaxIdleConnections = "25"
const defaultDbMaxOpenConnections = "25"
const defaultDbIngestionTimeInterval = "60"

const defaultFallbackLocale = "en-us"

const numOfInitParams = 3

const stringToIntConversionErrMsg = "failed to convert %s string value to int"

// CommitSHA is the git commit sha
var CommitSHA string

// CommitName is the git commit name
var CommitName string

// BuildDate is the build date
var BuildDate string

// ServiceName is the service name
var ServiceName string

// Env is the environment the service is running in
var Env string

// WebServerPort is the web server port for localization service API, defaulted to 3000
var WebServerPort string

// LogsLevel is the logs level, e.g. 1 -> DEBUG
var LogsLevel int

var DbName string
var DbHost string
var DbPort string
var DbUser string
var DbPassword string

// DbMaxIdleConnections is the number of max idle DB connections
var DbMaxIdleConnections int

// DbMaxOpenConnections is the number of max opened DB connections
var DbMaxOpenConnections int

// DbIngestionTimeInterval is the time interval between DB ingestions
var DbIngestionTimeInterval int

// FallbackLocale is the locale fallback
var FallbackLocale string

// InitConfig initializes the initial service state, mainly configured through the env variables
func InitConfig(params ...string) {
	var err error

	commitName := NoneValue
	commitSha := NoneValue
	buildDate := NoneValue

	if len(params) >= numOfInitParams {
		commitName = params[0]
		commitSha = params[1]
		buildDate = params[2]
	}

	CommitName = getEnv(commitNameKey, commitName)
	CommitSHA = getEnv(commitSHAKey, commitSha)
	BuildDate = getEnv(buildDateKey, buildDate)

	ServiceName = getEnv(serviceNameKey, DefaultServiceName)
	Env = getEnv(envKey, DefaultEnv)
	WebServerPort = getEnv(webServerPortKey, defaultWebServerPort)

	LogsLevel, err = strconv.Atoi(getEnv(logsLevelKey, defaultLogsLevel))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, logsLevelKey)
		LogsLevel, _ = strconv.Atoi(defaultLogsLevel)
	}

	// use default db settings for dev purposes
	DbHost = getEnv(dbHostKey, defaultDbHost)
	DbPort = getEnv(dbPortKey, defaultDbPort)
	DbUser = getEnv(dbUserKey, defaultDbUser)
	DbPassword = getEnv(dbPasswordKey, defaultDbPassword)
	DbName = getEnv(dbNameKey, defaultDbName)

	DbMaxIdleConnections, err = strconv.Atoi(getEnv(dbMaxIdleConnectionsKey, defaultDbMaxIdleConnections))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, dbMaxIdleConnectionsKey)
		DbMaxIdleConnections, _ = strconv.Atoi(defaultDbMaxIdleConnections)
	}
	DbMaxOpenConnections, err = strconv.Atoi(getEnv(dbMaxOpenConnectionsKey, defaultDbMaxOpenConnections))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, dbMaxOpenConnectionsKey)
		DbMaxOpenConnections, _ = strconv.Atoi(defaultDbMaxOpenConnections)
	}

	DbIngestionTimeInterval, err = strconv.Atoi(getEnv(dbIngestionTimeIntervalKey, defaultDbIngestionTimeInterval))
	if err != nil {
		log.Errorf(stringToIntConversionErrMsg, dbIngestionTimeIntervalKey)
		DbIngestionTimeInterval, _ = strconv.Atoi(defaultDbIngestionTimeInterval)
	}

	FallbackLocale = getEnv(fallbackLocaleKey, defaultFallbackLocale)

	// regex
	CompileLocalizationServiceRegexes()

	// configure logging
	ConfigureLogs(LogsLevel)

	log.Infof("%s config has been initialized", ServiceName)

}

// ConfigureLogs is the function to configure logs
func ConfigureLogs(logsLevel int) {
	// 1 -> DEBUG
	// 2 -> INFO
	// 3 -> WARN
	// 4 -> ERROR
	// 5 -> OFF
	log.SetLevel(log.Lvl(logsLevel))
	log.SetHeader("${time_rfc3339} ${level} ${short_file} ${line}")

}

func getEnv(key, fallback string) string {
	value := os.Getenv(key)
	if len(value) == 0 {
		return fallback
	}
	return value
}
