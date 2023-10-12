package main

import (
	"database/sql"
	"strconv"

	"github.com/go-redis/redis/v8"
)

const (
	maxCloseWaitSecs                        = 10
	ENVVAR_FW_PROP_TASK_POLL_INTERVAL_SECS  = "DS_FW_PROP_TASK_POLL_INTERVAL_SECS"
	DEFAULT_FW_PROP_TASK_POLL_INTERVAL_SECS = 60
)

type Processor interface {
	Open()
	Close()
}

func StopTaskProcessors(processors []Processor) {

	for _, p := range processors {
		p.Close()
	}
}
func InitTaskProcessors(db *sql.DB, redis *redis.ClusterClient) []Processor {
	pollInterval := DEFAULT_FW_PROP_TASK_POLL_INTERVAL_SECS

	if n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_FW_PROP_TASK_POLL_INTERVAL_SECS, "")); e == nil && n > 0 {
		pollInterval = n
	}
	taskRepository := PgTaskRepository{DB: db}
	deviceRepository := &PgDeviceRepository{DB: db}

	processors := []Processor{
		CreateFwProvisioningProcessor(pollInterval, taskRepository, deviceRepository, redis),
	}

	for _, p := range processors {
		p.Open()
	}
	return processors
}
