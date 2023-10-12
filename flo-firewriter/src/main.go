package main

import (
	"fmt"
	"os"
	"os/signal"
	"runtime"
	"syscall"
	"time"

	_ "net/http/pprof"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

// These global variables are set by GO compiler if provided
var commitName string
var commitSha string
var commitTime string

// @title Firewriter service
// @version 1.0
// @summary This is microservice responsible for read and writes to Firestore
// @description This is microservice responsible for read and writes to Firestore
// @contact.name Alexander Galushka
// @contact.email alex.galushka@flotechnologies.com
// @host flo-firewriter.flocloud.co
// @schemes http https
func main() {
	logNotice("ServiceStart: " + ServiceName)

	numCPUs := runtime.NumCPU()
	logDebug("%s has %d logical usable CPUs", ServiceName, numCPUs)

	logDebug("%s has %d goroutines after profiling kick-off", ServiceName, runtime.NumGoroutine())

	// initialize service configuration
	InitConfig(commitName, commitSha, commitTime)

	logDebug("%s has %d goroutines after initializing logs", ServiceName, runtime.NumGoroutine())

	// initialize Firestore
	fs, err := InitFirestore()
	if err != nil {
		logFatal("failed to initialize firestore, err: %v", err)
	}

	fsRepo := FsWriterRepo{
		Firestore: fs,
	}

	logDebug("%s has %d goroutines after initializing firestore", ServiceName, runtime.NumGoroutine())

	err = StartWriterProcesses(&fsRepo)
	if err != nil {
		logFatal("failed to start writer processes, err: %v", err)
	}

	logDebug("%s has %d goroutines after initializing writer processes", ServiceName, runtime.NumGoroutine())

	StartWorkRequestsProcessing()

	logDebug("%s has %d goroutines after starting work requests processing", ServiceName, runtime.NumGoroutine())

	logDebug("%s has %d goroutines after initializing kafka consumers", ServiceName, runtime.NumGoroutine())

	kafkaConnection, err := CreateKafkaConnection(KafkaBrokerUrls)
	if err != nil {
		logFatal("error creating kafka connection - %v", err)
	}
	logInfo("kafka connection: OK")

	err = InitKafkaConsumer(kafkaConnection)
	if err != nil {
		logFatal("failed to start kafka consumers, err %v", err)
	}
	logInfo("kafka consumer: OK")

	logDebug("%s has %d goroutines after initializing kafka", ServiceName, runtime.NumGoroutine())

	InitHttpRequestsHandlers(kafkaConnection, &fsRepo)

	logDebug("%s has %d goroutines after initializing http requests Handlers", ServiceName, runtime.NumGoroutine())

	// preset echo
	e := NewInstaecho()
	e.Use(setupLogger())
	e.Pre(middleware.RemoveTrailingSlash())
	e.Use(middleware.CORS())

	// initialize all the routes
	InitRouters(e)

	logDebug("%s has %d goroutines before starting web server", ServiceName, runtime.NumGoroutine())

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL)
	go func() {
		// Block until we receive our signal.
		<-sigChan
		kafkaConnection.Close()
		time.Sleep(time.Second * 5)
		logNotice("ServiceStop: " + ServiceName)
		os.Exit(0)
	}()

	// kick echo web server
	err = e.Start(fmt.Sprintf(":%s", WebServerPort))
	if err != nil {
		logFatal("failed to start web server, err: %v", err)
	}
}

func echoLogSkipper(c echo.Context) bool {
	return !(_log.MinLevel <= LL_DEBUG)
}

func setupLogger() echo.MiddlewareFunc {
	var ourLogConfig = middleware.LoggerConfig{
		Skipper:          echoLogSkipper,
		Format:           `${time_rfc3339} DEBUG ${status} ${method} ${uri} ${remote_ip} ${latency_human} "${user_agent}" ${error}` + "\n",
		CustomTimeFormat: time.RFC3339,
		Output:           os.Stdout,
	}
	return middleware.LoggerWithConfig(ourLogConfig)
}
