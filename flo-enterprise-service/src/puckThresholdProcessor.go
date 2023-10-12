package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"

	"github.com/pkg/errors"
)

const logCode = "puckThresholdTask"

type puckThresholdProcessor struct {
	log              *Logger
	mudRepository    MudTaskRepository
	redis            *RedisConnection
	pubGwService     *pubGwService
	deviceService    *deviceService
	pollIntervalSecs int
	isOpen           int32
	isRunning        int32
}

func NewPuckThresholdProcessor(log *Logger, mudRepository MudTaskRepository, redis *RedisConnection,
	pubGWService *pubGwService, deviceService *deviceService) Processor {
	pollInterval, err := strconv.Atoi(getEnvOrDefault("FLO_PUCK_PROCESSOR_POLL_INTERVAL_SECS", strconv.Itoa(defaultShortPollIntervalSecs)))
	if err != nil {
		pollInterval = defaultShortPollIntervalSecs
	}

	return createPuckThresholdProcessor(log, pollInterval, mudRepository, redis, pubGWService, deviceService)
}

func createPuckThresholdProcessor(log *Logger, pollIntervalSecs int, mudRepository MudTaskRepository, redis *RedisConnection,
	pubGWService *pubGwService, deviceService *deviceService) Processor {
	return &puckThresholdProcessor{
		log:              log.CloneAsChild("puckThresholdProcessor"),
		pollIntervalSecs: pollIntervalSecs,
		mudRepository:    mudRepository,
		redis:            redis,
		pubGwService:     pubGWService,
		deviceService:    deviceService,
	}
}

func (tp *puckThresholdProcessor) Open() {
	if atomic.CompareAndSwapInt32(&tp.isOpen, 0, 1) {
		tp.log.Debug("Open: begin")
		go tp.runProcessor()
	} else {
		tp.log.Warn("Open: already opened")
	}
}

func (tp *puckThresholdProcessor) Close() {
	safelyCloseProcessor(&tp.isOpen, &tp.isRunning, tp.log)
}

func (tp *puckThresholdProcessor) runProcessor() {
	defer panicRecover(tp.log, "runProcessor: %p", tp)

	autoResetScheduler(&tp.isOpen, tp.pollIntervalSecs, func() {
		tp.log.Info("runProcessor: processing devices with pending tasks")
		go tp.processPendingDevices(context.Background())
		tp.log.Info("runProcessor: sleeping for %d seconds", tp.pollIntervalSecs)
	})
}

func (tp *puckThresholdProcessor) processPendingDevices(ctx context.Context) {
	defer panicRecover(tp.log, "processPendingDevices: %p", tp)

	atomic.StoreInt32(&tp.isRunning, 1)
	defer func() {
		atomic.StoreInt32(&tp.isRunning, 0)
	}()

	tasks, err := tp.mudRepository.GetTasks(ctx,
		TaskFilter{
			Type:   Type_DefaultSettings,
			Status: []TaskStatus{TS_Pending},
		})
	if err != nil {
		tp.log.Warn("processPendingDevices: error getting tasks - %v", err)
		return
	}

	tp.log.Debug("processPendingDevices: retrieved %d tasks", len(tasks))

	for _, t := range tasks {
		tp.log.Debug("processPendingDevices: acquiring lock")
		key := fmt.Sprintf("mutex:floEnterpriseService:puckThresholdProcessor:processPendingDevices:%v", t.MacAddress)
		lockAcquired, err := processorAcquireLock(tp.redis, key, tp.pollIntervalSecs)
		if err != nil {
			tp.log.Warn("processPendingDevices: error acquiring lock - %v", err)
			continue
		}

		if !lockAcquired {
			tp.log.Trace("processPendingDevices: lock was acquired by another instance")
			continue
		}

		err = tp.processThresholdTask(ctx, t)
		if err != nil {
			tp.log.Warn("processPendingDevices: error processing task id %v for device %v - %v", t.Id, t.MacAddress, err)
		}

		_, err = tp.redis.Delete(key)
		if err != nil {
			tp.log.Warn("processPendingDevices: error releasing lock - %v", err)
		}
	}

	tp.log.Info("processPendingDevices: finished processing %d tasks", len(tasks))
}

func (tp *puckThresholdProcessor) processThresholdTask(ctx context.Context, task *Task) error {
	tp.log.Info("%s: processing task id: %v, device: %v", logCode, task.Id, task.MacAddress)

	device, err := tp.deviceService.getDevice(ctx, task.MacAddress)
	if err != nil {
		return errors.Wrapf(err, "%s: error getting device %v from device service", logCode, task.MacAddress)
	}

	if !strings.EqualFold(device.DeviceType, DT_Puck) {
		tp.log.Trace("%s: skipping task, can't handle device %v", logCode, task.MacAddress)
		return nil
	}

	thresholdDefaults, err := tp.resolveDefaultValues(ctx, task)
	if err != nil || thresholdDefaults == nil {
		return errors.Wrapf(err, "processThresholdTask: error resolving default values for device %v", task.MacAddress)
	}

	puckHwThresholds := tp.buildHwThresholdsPayload(thresholdDefaults)
	err = tp.deviceService.updateHwThresholds(ctx, task.MacAddress, puckHwThresholds)
	if err != nil {
		return errors.Wrapf(err, "%s: error updating hw thresholds for device %v", logCode, task.MacAddress)
	}
	err = updateTaskStatus(ctx, tp.mudRepository, task, TS_Completed)
	if err != nil {
		return errors.Wrapf(err, "%s: error updating task status for task with id %v", logCode, task.Id)
	}

	tp.log.Info("%s: successfully processed task id: %v, device: %v", logCode, task.Id, task.MacAddress)
	return nil
}

func (tp *puckThresholdProcessor) buildHwThresholdsPayload(thresholdDefaults *PuckThresholdValues) *HardwareThresholdPayload {
	return &HardwareThresholdPayload{
		TempF:           &ThresholdDefinitionPayload{OkMin: thresholdDefaults.MinTempF, OkMax: thresholdDefaults.MaxTempF},
		Humidity:        &ThresholdDefinitionPayload{OkMin: thresholdDefaults.MinHumidity, OkMax: thresholdDefaults.MaxHumidity},
		Battery:         &ThresholdDefinitionPayload{OkMin: thresholdDefaults.MinBattery, OkMax: thresholdDefaults.MaxBattery},
		TempEnabled:     true,
		HumidityEnabled: true,
		BatteryEnabled:  true,
	}
}

func (tp *puckThresholdProcessor) resolveDefaultValues(ctx context.Context, task *Task) (*PuckThresholdValues, error) {
	device, err := tp.pubGwService.getDevice(ctx, task.MacAddress, "location(account)")
	if err != nil {
		return nil, errors.Wrapf(err, "resolveDefaultValues: unable to get deviceInfo from PubGW for device %v", task.MacAddress)
	}
	defaults, err := tp.mudRepository.GetDefaultThresholds(ctx, &device.Location.Account.Id, device.DeviceType)
	if err != nil {
		return nil, errors.Wrapf(err, "resolveDefaultValues: unable to get defaults from DB for account %v", device.Location.Account.Id)
	}
	if defaults == nil {
		tp.log.Debug("resolveDefaultValues: default values were not found for account id %v. Retrieving global defaults...", device.Location.Account.Id)
		defaults, err := tp.mudRepository.GetDefaultThresholds(ctx, nil, device.DeviceType)
		if err != nil {
			return nil, errors.Wrap(err, "resolveDefaultValues: unable to get GLOBAL defaults from DB")
		}
		if defaults == nil {
			return nil, errors.Errorf("resolveDefaultValues: GLOBAL default values were not found in the DB")
		}
	}
	defaultValues := PuckThresholdValues{}
	err = json.Unmarshal([]byte(*defaults.DefaultValues), &defaultValues)
	if err != nil {
		return nil, errors.Wrapf(err, "resolveDefaultValues: error deserializing json %v.", defaults.DefaultValues)
	}

	return &defaultValues, nil
}
