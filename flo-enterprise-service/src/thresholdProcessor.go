package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"

	"github.com/hashicorp/go-version"
	"github.com/pkg/errors"
)

type Processor interface {
	Open()
	Close()
}

type thresholdProcessor struct {
	log              *Logger
	mudRepository    MudTaskRepository
	redis            *RedisConnection
	pubGwService     *pubGwService
	deviceService    *deviceService
	floSenseService  *floSenseService
	pollIntervalSecs int
	isOpen           int32
	isRunning        int32
	minFwVersion     string
}

func NewThresholdProcessor(log *Logger, mudRepository MudTaskRepository, redis *RedisConnection,
	pubGWService *pubGwService, deviceService *deviceService, floSenseService *floSenseService) Processor {
	pollInterval, err := strconv.Atoi(getEnvOrDefault("FLO_PROCESSOR_POLL_INTERVAL_SECS", strconv.Itoa(defaultLongPollIntervalSecs)))
	if err != nil {
		pollInterval = defaultLongPollIntervalSecs
	}

	minFwVersion := getEnvOrExit("MIN_FLO_SENSE_FW_VERSION")
	return createThresholdProcessor(log, pollInterval, mudRepository, redis, pubGWService, deviceService, minFwVersion, floSenseService)
}

func createThresholdProcessor(log *Logger, pollIntervalSecs int, mudRepository MudTaskRepository, redis *RedisConnection,
	pubGWService *pubGwService, deviceService *deviceService, minFwVersion string, floSenseService *floSenseService) Processor {
	return &thresholdProcessor{
		log:              log.CloneAsChild("thresholdProcessor"),
		pollIntervalSecs: pollIntervalSecs,
		mudRepository:    mudRepository,
		redis:            redis,
		pubGwService:     pubGWService,
		deviceService:    deviceService,
		minFwVersion:     minFwVersion,
		floSenseService:  floSenseService,
	}
}

func (tp *thresholdProcessor) Open() {
	if atomic.CompareAndSwapInt32(&tp.isOpen, 0, 1) {
		tp.log.Debug("Open: begin")
		go tp.runProcessor()
	} else {
		tp.log.Warn("Open: already opened")
	}
}

func (tp *thresholdProcessor) Close() {
	safelyCloseProcessor(&tp.isOpen, &tp.isRunning, tp.log)
}

func (tp *thresholdProcessor) runProcessor() {
	defer panicRecover(tp.log, "runProcessor: %p", tp)

	autoResetScheduler(&tp.isOpen, tp.pollIntervalSecs, func() {
		tp.log.Info("runProcessor: processing devices with pending tasks")
		go tp.processPendingDevices()
		tp.log.Trace("runProcessor: sleeping for %d seconds", tp.pollIntervalSecs)
	})
}

func (tp *thresholdProcessor) processPendingDevices() {
	defer panicRecover(tp.log, "processPendingDevices: %p", tp)

	atomic.StoreInt32(&tp.isRunning, 1)
	defer func() {
		atomic.StoreInt32(&tp.isRunning, 0)
	}()

	ctx := context.Background()

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
		key := fmt.Sprintf("mutex:floEnterpriseService:thresholdProcessor:processPendingDevices:%v", t.MacAddress)
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

func (tp *thresholdProcessor) processThresholdTask(ctx context.Context, task *Task) error {
	tp.log.Info("processThresholdTask: processing task id: %v, device: %v", task.Id, task.MacAddress)

	device, err := tp.deviceService.getDevice(ctx, task.MacAddress)
	if err != nil {
		return errors.Wrapf(err, "processThresholdTask: error getting device %v from device service", task.MacAddress)
	}
	if !strings.EqualFold(device.DeviceType, DT_Valve) {
		tp.log.Trace("processThresholdTask: skipping task, can't handle device %v", logCode, task.MacAddress)
		return nil
	}

	deviceVersion, err := version.NewVersion(device.FwVersion)
	if err != nil {
		return errors.Wrapf(err, "processThresholdTask: error reading device version. version [%v]", device.FwVersion)
	}
	minVersion, err := version.NewVersion(tp.minFwVersion)
	if err != nil {
		return errors.Wrap(err, "processThresholdTask: error reading min FW version")
	}

	if deviceVersion.LessThan(minVersion) {
		tp.log.Debug("processThresholdTask: device %v does not have min fwVer to set thresholds - curr dev version: %v", task.MacAddress, device.FwVersion)
		return nil
	}

	thresholdDefaults, err := tp.resolveDefaultValues(ctx, task)
	if err != nil || thresholdDefaults == nil {
		return errors.Wrapf(err, "processThresholdTask: error resolving default values for device %v", task.MacAddress)
	}
	payload := tp.buildFloSensePayload(task.MacAddress, thresholdDefaults)
	err = tp.floSenseService.update(ctx, task.MacAddress, payload)
	if err != nil {
		return errors.Wrapf(err, "processThresholdTask: error updating floSense for device %v", task.MacAddress)
	}
	tp.log.Debug("processThresholdTask: successfully sent thresholds to floSense - POST/devices/%v - %v", task.MacAddress, payload)

	err = tp.updateTaskStatus(ctx, task, TS_InProgress)
	if err != nil {
		return errors.Wrapf(err, "processThresholdTask: error updating task status for task with id %v", task.Id)
	}

	tp.log.Info("processThresholdTask: successfully processed task id: %v, device: %v", task.Id, task.MacAddress)
	return nil
}

func (tp *thresholdProcessor) updateTaskStatus(ctx context.Context, task *Task, status TaskStatus) error {
	task.Status = status
	_, err := tp.mudRepository.UpdateTask(ctx, task)
	return err
}

func (tp *thresholdProcessor) resolveDefaultValues(ctx context.Context, task *Task) (*ValveThresholdValues, error) {
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
		defaults, err = tp.mudRepository.GetDefaultThresholds(ctx, nil, device.DeviceType)
		if err != nil {
			return nil, errors.Wrap(err, "resolveDefaultValues: unable to get GLOBAL defaults from DB")
		}
		if defaults == nil {
			return nil, errors.Errorf("resolveDefaultValues: GLOBAL default values were not found in the DB")
		}
	}
	defaultValues := ValveThresholdValues{}
	err = json.Unmarshal([]byte(*defaults.DefaultValues), &defaultValues)
	if err != nil {
		return nil, errors.Wrapf(err, "resolveDefaultValues: error deserializing json %v.", defaults.DefaultValues)
	}
	return &defaultValues, nil
}

func (tp *thresholdProcessor) buildFloSensePayload(macAddress string, thresholdDefaults *ValveThresholdValues) *UpdateFloSensePayload {
	var (
		shutoffDisabled  = false
		shutoffDelayHome = 300
		shutoffDelayAway = 0
		userEnabled      = false
	)

	return &UpdateFloSensePayload{
		MacAddress: macAddress,
		FloSense: &FloSense{
			UserEnabled: &userEnabled,
			PesOverride: &FloSenseOverride{
				Home: &PesScheduleItem{
					EventLimits: PesEventLimits{
						Duration:         thresholdDefaults.Duration,
						Volume:           thresholdDefaults.Volume,
						FlowRate:         thresholdDefaults.FlowRate,
						FlowRateDuration: 20,
					},
					ShutoffDisabled: &shutoffDisabled,
					ShutoffDelay:    &shutoffDelayHome,
				},
				Away: &PesScheduleItem{
					EventLimits: PesEventLimits{
						Duration:         thresholdDefaults.Duration,
						Volume:           thresholdDefaults.Volume,
						FlowRate:         thresholdDefaults.FlowRate,
						FlowRateDuration: 5,
					},
					ShutoffDisabled: &shutoffDisabled,
					ShutoffDelay:    &shutoffDelayAway,
				},
			},
		},
	}
}
