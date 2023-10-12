package main

import (
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

const defaultAppName = "flo-task-scheduler-v2"
const defaultPollIntervalSecs = 5
const defaultTimeoutSeconds = 10

type AppInfo struct {
	commitSha    string
	commitBranch string
	hostName     string
	appName      string
	appStart     time.Time
}

var (
	signalChannel chan os.Signal
)

func signalExit() {
	signalChannel <- syscall.SIGABRT
}

func init() {
	signalChannel = make(chan os.Signal, 1)
}

func main() {
	log := DefaultLogger()
	appInfo := &AppInfo{
		commitSha:    getEnvOrDefault("CI_COMMIT_SHA", ""),
		commitBranch: getEnvOrDefault("CI_COMMIT_BRANCH", ""),
		hostName:     getHostname(),
		appName:      getEnvOrDefault("APPLICATION_NAME", defaultAppName),
		appStart:     time.Now(),
	}

	var (
		kafkaConnection = initKafka(log)
		pgSql           = initPgSql(log)
		redis           = initRedis(log)
		httpClient      = initHttp()
	)

	log.Info("main: creating task repository")
	taskRepository := CreateTaskRepository(log, pgSql)
	log.Info("main: task repository successfully created")

	log.Info("main: creating executor")
	executor := createExecutor(log, kafkaConnection, taskRepository, httpClient)
	log.Info("main: executor successfully created")

	log.Info("main: creating scheduler")
	scheduler := createScheduler(log, kafkaConnection, taskRepository, redis)
	log.Info("main: scheduler successfully created")

	resources := []Resource{
		executor,
		scheduler,
	}
	services := &Services{
		scheduler: scheduler,
	}

	log.Info("main: creating web server")
	ws := CreateWebServer(log, appInfo, registerRoutes(log, appInfo, services), resources)
	log.Info("main: starting web server")
	ws.Start()

	signal.Notify(signalChannel, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
	sig, ok := <-signalChannel
	if !ok {
		log.Debug("main: console signal close received")
	}
	log.Info("main: stopping web server")
	ws.Stop()

	close(signalChannel)
	log.Info("main: stopped - uptime was %v", time.Since(appInfo.appStart))
	if sig == syscall.SIGABRT {
		os.Exit(-11)
	} else {
		os.Exit(0)
	}
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

func initHttp() *http.Client {
	timeoutSecs, _ := strconv.Atoi(getEnvOrDefault("FLO_HTTP_TIMEOUT_SECONDS", ""))
	if timeoutSecs < 0 {
		timeoutSecs = defaultTimeoutSeconds
	}
	timeout := time.Duration(int64(timeoutSecs)) * time.Second

	return &http.Client{Timeout: timeout}
}

func createExecutor(log *Logger, kafkaConnection *KafkaConnection, taskRepository TaskRepository, httpClient *http.Client) Executor {
	return CreateTaskExecutor(log, &ExecutorKafkaConfig{
		kafkaConnection: kafkaConnection,
		groupId:         getEnvOrExit("FLO_KAFKA_GROUP_ID"),
		topic:           getEnvOrExit("FLO_KAFKA_TOPIC"),
	}, taskRepository, httpClient)
}

func createScheduler(log *Logger, kafkaConnection *KafkaConnection, taskRepository TaskRepository, redis *RedisConnection) Scheduler {
	pollInterval, err := strconv.Atoi(getEnvOrDefault("FLO_POLL_INTERVAL_SECS", strconv.Itoa(defaultPollIntervalSecs)))
	if err != nil {
		pollInterval = defaultPollIntervalSecs
	}
	return CreateScheduler(log, pollInterval, &SchedulerKafkaConfig{
		kafkaConnection: kafkaConnection,
		topic:           getEnvOrExit("FLO_KAFKA_TOPIC"),
	}, taskRepository, redis)
}
