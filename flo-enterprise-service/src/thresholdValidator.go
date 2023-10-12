package main

import (
	"context"
	"fmt"
	"strconv"
	"sync/atomic"

	"github.com/pkg/errors"
)

type ThresholdValidator interface {
	Open()
	Close()
}

type thresholdValidator struct {
	log              *Logger
	mudRepository    MudTaskRepository
	redis            *RedisConnection
	pubGwService     *pubGwService
	floSenseService  *floSenseService
	pollIntervalSecs int
	isOpen           int32
	isRunning        int32
}

func NewThresholdValidator(log *Logger, mudRepository MudTaskRepository, redis *RedisConnection,
	pubGWService *pubGwService, floSenseService *floSenseService) Processor {
	pollInterval, err := strconv.Atoi(getEnvOrDefault("FLO_VALIDATOR_POLL_INTERVAL_SECS", strconv.Itoa(defaultShortPollIntervalSecs)))
	if err != nil {
		pollInterval = defaultShortPollIntervalSecs
	}

	return createThresholdValidator(log, pollInterval, mudRepository, redis, pubGWService, floSenseService)
}

func createThresholdValidator(log *Logger, pollIntervalSecs int, mudRepository MudTaskRepository, redis *RedisConnection,
	pubGWService *pubGwService, floSenseService *floSenseService) ThresholdValidator {
	return &thresholdValidator{
		log:              log.CloneAsChild("thresholdValidator"),
		pollIntervalSecs: pollIntervalSecs,
		mudRepository:    mudRepository,
		redis:            redis,
		pubGwService:     pubGWService,
		floSenseService:  floSenseService,
	}
}

func (v *thresholdValidator) Open() {
	if atomic.CompareAndSwapInt32(&v.isOpen, 0, 1) {
		v.log.Debug("Open: begin")
		go v.runValidator()
	} else {
		v.log.Warn("Open: already opened")
	}
}

func (v *thresholdValidator) Close() {
	safelyCloseProcessor(&v.isOpen, &v.isRunning, v.log)
}

func (v *thresholdValidator) runValidator() {
	defer panicRecover(v.log, "runValidator: %p", v)

	autoResetScheduler(&v.isOpen, v.pollIntervalSecs, func() {
		v.log.Info("runValidator: processing devices with in-progress tasks")
		go v.validateTasks(context.Background())
		v.log.Info("runValidator: sleeping for %d seconds", v.pollIntervalSecs)
	})
}

func (v *thresholdValidator) validateTasks(ctx context.Context) {
	defer panicRecover(v.log, "validateTasks: %p", v)

	atomic.StoreInt32(&v.isRunning, 1)
	defer func() {
		atomic.StoreInt32(&v.isRunning, 0)
	}()

	tasks, err := v.mudRepository.GetTasks(ctx, TaskFilter{
		Type:   Type_DefaultSettings,
		Status: []TaskStatus{TS_InProgress},
	})
	if err != nil {
		v.log.Warn("validateTasks: error getting tasks - %v", err)
		return
	}

	v.log.Debug("validateTasks: retrieved %d tasks", len(tasks))

	for _, t := range tasks {
		key := fmt.Sprintf("mutex:floEnterpriseService:thresholdValidator:validateTasks:%v", t.MacAddress)
		lockAcquired, err := processorAcquireLock(v.redis, key, v.pollIntervalSecs)
		if err != nil {
			v.log.Warn("validateTasks: error acquiring lock - %v", err)
			continue
		}

		if !lockAcquired {
			v.log.Trace("validateTasks: lock was acquired by another instance")
			continue
		}

		err = v.validateThresholdTask(ctx, t)
		if err != nil {
			v.log.Warn("validateTasks: error processing task id %v for device %v - %v", t.Id, t.MacAddress, err)
		}

		_, err = v.redis.Delete(key)
		if err != nil {
			v.log.Warn("validateTasks: error releasing lock - %v", err)
		}
	}

	v.log.Info("validateTasks: finished processing %d tasks", len(tasks))
}

func (v *thresholdValidator) validateThresholdTask(ctx context.Context, task *Task) error {
	v.log.Info("validateThresholdTask: validating task id: %v, device: %v", task.Id, task.MacAddress)

	floSenseData, err := v.floSenseService.getDevice(ctx, task.MacAddress)
	if err != nil {
		return errors.Wrapf(err, "validateThresholdTask: error getting floSense data for device %v from science-lab", task.MacAddress)
	}
	if floSenseData.FloSense == nil || floSenseData.Pes.Schedule.SyncRequired {
		v.log.Debug("validateThresholdTask: floSense changes for device %v have not been confirmed yet", task.MacAddress)
		return nil
	}

	err = v.updateSystemMode(ctx, task.MacAddress)
	if err != nil {
		return errors.Wrapf(err, "validateThresholdTask: error updating system mode for device %v", task.MacAddress)
	}

	task.Status = TS_Completed
	_, err = v.mudRepository.UpdateTask(ctx, task)
	if err != nil {
		return errors.Wrapf(err, "validateThresholdTask: error updating task status for task with id %v", task.Id)
	}

	v.log.Info("validateThresholdTask: successfully validated task id: %v, device: %v", task.Id, task.MacAddress)
	return nil
}

func (v *thresholdValidator) updateSystemMode(ctx context.Context, macAddress string) error {
	device, err := v.pubGwService.getDevice(ctx, macAddress, "location")
	if err != nil {
		return errors.Wrapf(err, "updateSystemMode: unable to get deviceInfo from PubGW for device %v", macAddress)
	}

	if !device.SystemMode.IsLocked {
		v.log.Info("updateSystemMode: device system mode not in locked sleep, skipping. %v %v", macAddress, device.SystemMode)
		return nil
	}

	// validate and LOG inconsistencies and continue unlocking the device.
	if device.SystemMode.Target != SM_Sleep || device.SystemMode.LastKnown != SM_Sleep {
		v.log.Debug("updateSystemMode: Inconsistencies found for device system mode (target/lastKnow). Proceed to unlock the device anyway. %v %v", macAddress, device.SystemMode)
	}

	isLocked := false
	targetUnlock := SM_Sleep
	// unlock the device
	err = v.pubGwService.setDeviceSystemMode(ctx, device.Id, &SystemModePayload{
		IsLocked: &isLocked,
		Target:   &targetUnlock,
	})
	if err != nil {
		return errors.Wrapf(err, "updateSystemMode: unable to unlock device %v - %v", macAddress, device.SystemMode)
	}

	// Do not put a device to sleep, put it in home mode if location is in sleep
	target := device.Location.SystemMode.Target
	if target == SM_Sleep || len(target) == 0 {
		target = SM_Home
	}

	err = v.pubGwService.setDeviceSystemMode(ctx, device.Id, &SystemModePayload{
		Target: &target,
	})
	if err != nil {
		return errors.Wrapf(err, "updateSystemMode: unable to update device system mode %v - %v", macAddress, device.SystemMode)
	}

	v.log.Debug("updateSystemMode: System mode successfully updated for device %v", macAddress)
	return nil
}
