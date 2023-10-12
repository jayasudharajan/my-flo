package main

import (
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

const defaultAppName = "flo-enterprise-service"
const defaultTimeoutSeconds = 10
const defaultLongPollIntervalSecs = 3600
const defaultShortPollIntervalSecs = 600

var (
	_commitSha          string
	_commitTime         string
	_hostName           string
	_appName            string
	_start              time.Time
	_osInterrupt        chan os.Signal
	_validator          *Validator
	_deviceServiceUrl   string
	_apiUrl             string
	_apiToken           string
	_floSenseServiceUrl string
)

type AppInfo struct {
	commitSha  string
	commitTime string
	hostName   string
	appName    string
	appStart   time.Time
}

func init() {
	_start = time.Now()
	_appName = getEnvOrDefault("APPLICATION_NAME", "flo-enterprise-service")
	_deviceServiceUrl = getEnvOrDefault("FLO_DEVICE_SERVICE_API_URL", "https://flo-device-service.flocloud.co")
	_floSenseServiceUrl = getEnvOrDefault("FLO_SCIENCE_LAB_API_URL", "http://flo-science-lab.flocloud.co")
	_apiUrl = getEnvOrDefault("FLO_API_URL", "https://api-gw-dev.flocloud.co")
	_apiToken = getEnvOrExit("FLO_API_TOKEN")
	_osInterrupt = make(chan os.Signal, 1)
}

func signalExit() {
	_osInterrupt <- syscall.SIGABRT
}

// @title flo-enterprise-service-v1 Api
// @version 1.0
// @description flo-enterprise-service-v1 Api Documentation
// @host flo-enterprise-service.flosecurecloud.com flo-enterprise-service.flocloud.co
// @schemes https http
func main() {
	logInfo("main: Starting...")

	_hostName = getHostname()
	appInfo := &AppInfo{
		commitSha:  _commitSha,
		commitTime: _commitTime,
		hostName:   _hostName,
		appName:    getEnvOrDefault("APPLICATION_NAME", defaultAppName),
		appStart:   time.Now(),
	}

	var (
		sig os.Signal
		ok  bool
	)
	_validator = CreateValidator(_log)

	// need to start tracer before the modules are created so that the tracer can be passed to the middleware hooks
	startTracing()

	var (
		httpUtil        = initHttp()
		kafkaConnection = initKafka(_log)
		pgSql           = initPgSql(_log)
		redis           = initRedis(_log)
	)

	_log.Info("main: creating mud task repository")
	mudTaskRepository := CreateMudTaskRepository(_log, pgSql)
	_log.Info("main: mud task repository successfully created")

	_log.Info("main: creating services")
	pubGwService := CreatePubGwService(_log, httpUtil, _apiUrl, _apiToken)
	deviceService := CreateDeviceService(_log, httpUtil, _deviceServiceUrl)
	floSenseService := CreateFloSenseService(_log, httpUtil, _floSenseServiceUrl)
	syncService := CreateSyncService(_log, pubGwService, mudTaskRepository, redis)
	entityActivityBroadcaster := createEntityActivityBroadcaster(_log, kafkaConnection, redis, pubGwService, syncService)
	_log.Info("main: services successfully created")

	_log.Info("main: create processors")
	deviceCollector := processorMilestone("device collector", func() Processor {
		return createDeviceCollector(_log, kafkaConnection, syncService, entityActivityBroadcaster)
	})
	thresholdProcessor := processorMilestone("threshold processor", func() Processor {
		return NewThresholdProcessor(_log, mudTaskRepository, redis, pubGwService, deviceService, floSenseService)
	})
	thresholdValidator := processorMilestone("threshold validator", func() Processor {
		return NewThresholdValidator(_log, mudTaskRepository, redis, pubGwService, floSenseService)
	})
	fwPropertiesProcessor := processorMilestone("fw properties", func() Processor {
		return NewFWPropertiesProcessor(_log, mudTaskRepository, redis, pubGwService, deviceService, floSenseService)
	})
	puckThresholdProcessor := processorMilestone("puck threshold", func() Processor {
		return NewPuckThresholdProcessor(_log, mudTaskRepository, redis, pubGwService, deviceService)
	})
	lteSyncProcessor := processorMilestone("lte sync", func() Processor {
		attSvcClient, err := CreateATTClient(httpUtil, _log)
		if err != nil {
			return nil
		}
		return NewLTESyncProcessor(_log, mudTaskRepository, redis, deviceService, pubGwService, attSvcClient)
	})
	_log.Info("main: processors successfully created")

	resources := []Resource{
		deviceCollector,
		thresholdProcessor,
		thresholdValidator,
		fwPropertiesProcessor,
		puckThresholdProcessor,
		lteSyncProcessor,
	}
	services := &Services{
		syncService,
	}

	if ws := CreateWebServer(_validator, _log, registerRoutes(_log, appInfo, services), resources).Open(); ws != nil {
		logInfo("main: Started")
		signal.Notify(_osInterrupt, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
		sig, ok = <-_osInterrupt
		fmt.Println()
		if !ok {
			logDebug("console signal close received")
		}
		logInfo("main: Stopping...")
		ws.Close()
	}

	close(_osInterrupt)
	logInfo("main: Stopped. Uptime was %v", time.Since(_start))
	if sig == syscall.SIGABRT {
		os.Exit(-11)
	} else {
		os.Exit(0)
	}
}

func processorMilestone(name string, creator func() Processor) Processor {
	logInfo("main: creating %s processor", name)
	result := creator()
	if result == nil {
		logError("main: %s not created", name)
	} else {
		logInfo("main: %s successfully created", name)
	}
	return result
}

func initHttp() *httpUtil {
	timeoutSecs, _ := strconv.Atoi(getEnvOrDefault("FLO_HTTP_TIMEOUT_SECONDS", ""))
	if timeoutSecs < 0 {
		timeoutSecs = defaultTimeoutSeconds
	}
	timeout := time.Duration(int64(timeoutSecs)) * time.Second

	return CreateHttpUtil("", _log, timeout).WithLogs()
}

func initKafka(log *Logger) *KafkaConnection {
	kafkaConnection, err := CreateKafkaConnection(log, getEnvOrExit("FLO_KAFKA_CN"))
	if err != nil {
		log.Fatal("initKafka: error creating kafka connection - %v", err)
		signalExit()
		return nil
	}
	log.Info("initKafka: OK")
	return kafkaConnection
}

func initPgSql(log *Logger) *PgSqlDb {
	db, e := CreatePgSqlDb(log, getEnvOrExit("FLO_PGDB_CN"))
	if e != nil {
		log.Fatal("initPgSql: error open connection - %v", e)
		signalExit()
		return nil
	}

	log.Info("initPgSql: OK")
	return db
}

func initRedis(log *Logger) *RedisConnection {
	redis, err := CreateRedisConnection(log, getEnvOrExit("FLO_REDIS_CN"))
	if err != nil {
		log.Fatal("initRedis: error connecting to redis - %v", err)
		signalExit()
		return nil
	}
	log.Info("initRedis: OK")
	return redis
}

func createEntityActivityBroadcaster(log *Logger, kafkaConnection *KafkaConnection, redis *RedisConnection, pubGWService *pubGwService, syncService SyncService) EntityActivityBroadcaster {
	awsSession, err := session.NewSession(&aws.Config{Region: aws.String("us-west-2")})
	tracing.WrapInstaawssdk(awsSession, tracing.Instana)
	if err != nil {
		_log.Fatal("Unable to create aws session. %v", err.Error())
		os.Exit(-1)
		return nil
	}
	eventBridgeClientConf := &AWSEventBridgeConfig{
		log:          _log.CloneAsChild("awsEventBridgeClient"),
		eventBusName: getEnvOrExit("FLO_ENTERPRISE_ACTIVITY_EVENT_BRIDGE_ARN"),
		source:       getEnvOrExit("FLO_ENTERPRISE_ACTIVITY_EVENT_BRIDGE_SOURCE"),
		session:      awsSession,
	}
	eventBridgeClient := CreateAWSEventBridgeClient(eventBridgeClientConf)
	entityActivityBroadcaster := CreateEntityActivityBroadcaster(log, redis, eventBridgeClient)
	return entityActivityBroadcaster
}

func createDeviceCollector(log *Logger, kafkaConnection *KafkaConnection, syncService SyncService, entityActivityBroadcaster EntityActivityBroadcaster) Resource {
	return CreateDeviceCollector(log, &CollectorKafkaConfig{
		kafkaConnection: kafkaConnection,
		groupId:         getEnvOrExit("FLO_KAFKA_ENTITY_ACTIVITY_GROUP_ID"),
		topic:           getEnvOrExit("FLO_KAFKA_ENTITY_ACTIVITY_TOPIC"),
	}, syncService, entityActivityBroadcaster)
}

func startTracing() {

	// preserve this isDebug() logic found in WebServer.go:CreateWebServer() to NOT initInstana if log.isDebug
	if _log.isDebug {
		tracing.SetDisableTracing(true)
	}
	tracing.StartTracing(_appName)
}
