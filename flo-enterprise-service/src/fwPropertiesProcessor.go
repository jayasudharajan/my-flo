package main

import (
	"context"
	"fmt"
	"strconv"
	"sync/atomic"

	"github.com/hashicorp/go-version"
	"github.com/pkg/errors"
)

const fwPropertiesProcessorMaxCloseWaitSecs = 10

type fwPropertiesProcessor struct {
	log              *Logger
	mudRepository    MudTaskRepository
	redis            *RedisConnection
	deviceService    *deviceService
	pollIntervalSecs int
	isOpen           int32
	isRunning        int32
	minFwVersion     string
}

func NewFWPropertiesProcessor(log *Logger, mudRepository MudTaskRepository, redis *RedisConnection, pubGWService *pubGwService, deviceService *deviceService, floSenseService *floSenseService) Processor {
	pollInterval, err := strconv.Atoi(getEnvOrDefault("FLO_FW_PROPERTIES_PROCESSOR_POLL_INTERVAL_SECS", strconv.Itoa(defaultLongPollIntervalSecs)))
	if err != nil {
		pollInterval = defaultLongPollIntervalSecs
	}

	minFwVersion := getEnvOrExit("MIN_FW_PROPERTIES_FW_VERSION")
	return createFWPropertiesProcessor(log, pollInterval, mudRepository, redis, deviceService, minFwVersion)
}

func createFWPropertiesProcessor(log *Logger, pollIntervalSecs int, mudRepository MudTaskRepository, redis *RedisConnection,
	deviceService *deviceService, minFwVersion string) Processor {

	return &fwPropertiesProcessor{
		log:              log.CloneAsChild("fwPropertiesProcessor"),
		pollIntervalSecs: pollIntervalSecs,
		mudRepository:    mudRepository,
		redis:            redis,
		deviceService:    deviceService,
		minFwVersion:     minFwVersion,
	}
}

func (tp *fwPropertiesProcessor) Open() {
	if atomic.CompareAndSwapInt32(&tp.isOpen, 0, 1) {
		tp.log.Debug("Open: begin")
		go tp.runProcessor()
	} else {
		tp.log.Warn("Open: already opened")
	}
}

func (tp *fwPropertiesProcessor) Close() {
	safelyCloseProcessor(&tp.isOpen, &tp.isRunning, tp.log)
}

func (tp *fwPropertiesProcessor) runProcessor() {
	defer panicRecover(tp.log, "runProcessor: %p", tp)

	autoResetScheduler(&tp.isOpen, tp.pollIntervalSecs, func() {
		tp.log.Info("runProcessor: processing devices with pending fw properties tasks")
		go tp.processPendingFwPropertiesDevices(context.Background())
		tp.log.Info("runProcessor: fw properties processor sleeping for %d seconds", tp.pollIntervalSecs)
	})
}

func (tp *fwPropertiesProcessor) processPendingFwPropertiesDevices(ctx context.Context) {
	defer panicRecover(tp.log, "processPendingFwPropertiesDevices: %p", tp)

	atomic.StoreInt32(&tp.isRunning, 1)
	defer func() {
		atomic.StoreInt32(&tp.isRunning, 0)
	}()

	tasks, err := tp.mudRepository.GetTasks(ctx,
		TaskFilter{
			Type:   Type_FWProperties,
			Status: []TaskStatus{TS_Pending},
		})
	if err != nil {
		tp.log.Warn("processPendingFwPropertiesDevices: error getting pending fw properties tasks - %v", err)
		return
	}

	tp.log.Debug("processPendingFwPropertiesDevices: retrieved %d fw properties tasks", len(tasks))

	for _, t := range tasks {
		tp.log.Debug("processPendingFwPropertiesDevices: acquiring lock")
		key := fmt.Sprintf("mutex:floEnterpriseService:fwPropertiesProcessor:processPendingFwPropertiesDevices:%v", t.MacAddress)
		lockAcquired, err := processorAcquireLock(tp.redis, key, tp.pollIntervalSecs)
		if err != nil {
			tp.log.Warn("processPendingFwPropertiesDevices: error acquiring lock - %v", err)
			continue
		}

		if !lockAcquired {
			tp.log.Trace("processPendingFwPropertiesDevices: lock was acquired by another instance")
			continue
		}

		err = tp.processFwPropertiesTask(ctx, t)
		if err != nil {
			tp.log.Warn("processPendingFwPropertiesDevices: error processing task id %v for device %v - %v", t.Id, t.MacAddress, err)
		}

		_, err = tp.redis.Delete(key)
		if err != nil {
			tp.log.Warn("processPendingFwPropertiesDevices: error releasing lock - %v", err)
		}
	}

	tp.log.Info("processPendingFwPropertiesDevices: finished processing %d tasks", len(tasks))
}

func (tp *fwPropertiesProcessor) processFwPropertiesTask(ctx context.Context, task *Task) error {
	tp.log.Info("processFwPropertiesTask: processing task id: %v, device: %v", task.Id, task.MacAddress)
	device, err := tp.deviceService.getDevice(ctx, task.MacAddress)
	if err != nil {
		return errors.Wrapf(err, "processFwPropertiesTask: error getting device %v from device service", task.MacAddress)
	}

	deviceVersion, err := version.NewVersion(device.FwVersion)
	if err != nil {
		return errors.Wrapf(err, "processFwPropertiesTask: error reading device version. version [%v]", device.FwVersion)
	}
	minVersion, err := version.NewVersion(tp.minFwVersion)
	if err != nil {
		return errors.Wrap(err, "processFwPropertiesTask: error reading min FW version")
	}

	if deviceVersion.LessThan(minVersion) {
		tp.log.Debug("processFwPropertiesTask: device %v does not have min fwVer to set fw properties - curr dev version: %v", task.MacAddress, device.FwVersion)
		return nil
	}

	fwProperties := tp.buildFwPropertiesPayload()
	err = tp.deviceService.setDeviceFwProperties(ctx, task.MacAddress, fwProperties)
	if err != nil {
		return errors.Wrapf(err, "processFwPropertiesTask: error updating fw properties for device %v", task.MacAddress)
	}

	task.Status = TS_Completed
	_, err = tp.mudRepository.UpdateTask(ctx, task)
	if err != nil {
		return errors.Wrapf(err, "processFwPropertiesTask: error updating task status for task with id %v", task.Id)
	}

	tp.log.Info("processFwPropertiesTask: successfully processed task id: %v, device: %v", task.Id, task.MacAddress)
	return nil
}

func (tp *fwPropertiesProcessor) buildFwPropertiesPayload() *FWPropertiesUpdatePayload {
	return &FWPropertiesUpdatePayload{
		TelemetryRealtimeEnabled:   true,
		TelemetryRealtimeInterval:  10,
		TelemetryRealtimeChangeGpm: 0.01,
		TelemetryRealtimeChangePsi: 1,
		TelemetryBatchedEnabled:    true,
		TelemetryBatchedInterval:   900,
		TelemetryBatchedHfEnabled:  false,
		FlodetectPostEnabled:       false,
		MenderPingDelay:            10800,
		LogEnabled:                 false,
	}
}
