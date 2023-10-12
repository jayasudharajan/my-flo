package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/labstack/gommon/log"
)

// These global variables are set by GO compiler if provided. Can be used to internally.
const APP_NAME = "flo-device-service"

var commitName string
var commitSha string
var commitTime string
var _hostname string
var _pgdb *sql.DB
var _redis *redis.ClusterClient
var _reconAudit ReconAudit
var _recon EnsureReconciliation
var _fwSync EnsureFwSync

// @title Device Service API
// @version 1.0
// @description This is service which takes provides information about FLO devices, its properties and states.

// @contact.name Alexander Galushka
// @contact.email alex.galushka@flotechnologies.com

// @host flo-device-service.flocloud.co
// @BasePath /v1
// @schemes http https
func main() {

	_hostname = getHostname()

	ctx := context.Background()

	// initialize service configuration
	InitConfig(commitName, commitSha, commitTime)

	// configure logging
	ConfigureLogs(LogsLevel)

	// initialize postgres database, e.g. Postgres
	db, err := InitRelationalDB()
	if err != nil {
		log.Fatal(err)
	}
	_pgdb = db
	_reconAudit = CreateReconAudit(db)

	rs, err := InitializeRedis()
	if err != nil {
		log.Fatal(err)
	}
	_redis = rs

	_recon = CreateEnsureReconciliation(rs, db)
	_fwSync = CreateEnsureSync(rs, db, _recon, _reconAudit)
	go _fwSync.Open()

	InitKafkaConsumerWorkProcessing(db, rs)

	err = InitializeFloHttpClient()
	if err != nil {
		log.Errorf("Failed to initialize http client, err: %v", err)
	}

	err = InitFirestore()
	if err != nil {
		log.Errorf("Failed to initialize Firestore, err: %v", err)
	}

	InitFireWriterHttpClient()
	InitHttpUtilClient()

	InitDeviceHttpRequestsHandlers(db, rs)
	InitTaskHttpRequestsHandlers(db)
	InitOnboardingLogHttpRequestsHandlers(db)
	InitActionRuleHttpRequestsHandlers(db)
	InitTaskProcessors(db, rs)

	niSch := CreateNeedInstallScheduler()
	niSch.initJob(ctx)

	// kick workers consuming off kafka
	// StartWorkersDispatcher(KafkaWorkersNum)
	// start consuming kafka messages

	if strings.EqualFold(getEnvOrDefault("DS_KAFKA_CONSUMER_OFF", ""), "true") {
		logNotice("DS_KAFKA_CONSUMER_OFF==true")
	} else if err = ConsumeKafkaMessages(); err != nil {
		log.Fatal(err)
	}

	// initialize MQTT publisher client
	_, err = InitMqttPublisher()
	if err != nil {
		log.Fatal(err)
	}

	if strings.EqualFold(getEnvOrDefault("DS_SM_RECON_OFF", ""), "true") {
		logNotice("DS_SM_RECON_OFF==true")
	} else { // This system reconciles system mode at interval
		go systemModeReconciliationWorker(context.Background())
	}

	// preset echo
	e := NewInstaecho() // use wrapped echo
	// TODO: consider to remove it, since too chatty
	e.Use(setupLogger())
	e.Use(middleware.Recover())
	e.Pre(middleware.RemoveTrailingSlash())
	e.Use(middleware.CORS())

	// e.HTTPErrorHandler = handlers.RequestErrorHandler
	InitRouters(e)

	// kick echo web server
	e.Logger.Fatal(e.Start(fmt.Sprintf(":%s", WebServerPort)))
}

func setupLogger() echo.MiddlewareFunc {
	var ourLogConfig = middleware.LoggerConfig{
		Skipper:          middleware.DefaultSkipper,
		Format:           `${time_rfc3339} INFO ${status} ${method} ${uri} ${remote_ip} ${latency_human} "${user_agent}" ${error}` + "\n",
		CustomTimeFormat: time.RFC3339,
		Output:           os.Stdout,
	}

	return middleware.LoggerWithConfig(ourLogConfig)
}
