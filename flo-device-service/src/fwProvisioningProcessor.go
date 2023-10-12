package main

import (
	"context"
	"device-service/models"
	"fmt"
	"regexp"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis/v8"
)

const fwProvisioningProcessorLogCode = "fwProvisioningProcessor"
const maxTasksPerCycle = 10

type fwProvisioningProcessor struct {
	pollIntervalSecs int
	taskRepo         TaskRepository
	deviceRepo       *PgDeviceRepository
	redis            *redis.ClusterClient
	isOpen           int32
	isRunning        int32
}

func CreateFwProvisioningProcessor(pollIntervalSecs int,
	taskRepo TaskRepository, deviceRepo *PgDeviceRepository, redis *redis.ClusterClient) Processor {
	return &fwProvisioningProcessor{
		pollIntervalSecs: pollIntervalSecs,
		taskRepo:         taskRepo,
		deviceRepo:       deviceRepo,
		redis:            redis,
	}
}

func (fwp *fwProvisioningProcessor) Open() {
	ctx := context.Background()
	if atomic.CompareAndSwapInt32(&fwp.isOpen, 0, 1) {
		logNotice("Open: begin")
		go fwp.run(ctx)
	} else {
		logWarn("Open: already opened")
	}
}

func (fwp *fwProvisioningProcessor) Close() {
	if atomic.CompareAndSwapInt32(&fwp.isOpen, 1, 0) {
		n := maxCloseWaitSecs
		for atomic.LoadInt32(&fwp.isRunning) == 1 && n > 0 {
			n--
			time.Sleep(1 * time.Second)
		}

		if atomic.LoadInt32(&fwp.isRunning) == 1 {
			logWarn("Close: processor is still running.")
			return
		}

		logNotice("Close: OK")
	} else {
		logWarn("Close: already closed")
	}
}

func (fwp *fwProvisioningProcessor) run(ctx context.Context) {
	atomic.StoreInt32(&fwp.isRunning, 1)
	defer func() {
		atomic.StoreInt32(&fwp.isRunning, 0)
	}()
	for atomic.LoadInt32(&fwp.isOpen) == 1 {
		logInfo("%s: processing devices with pending fw properties tasks", fwProvisioningProcessorLogCode)
		go fwp.processPending(ctx)
		logInfo("%s: fw provisioning processor sleeping for %d seconds",
			fwProvisioningProcessorLogCode, fwp.pollIntervalSecs)
		time.Sleep(time.Duration(fwp.pollIntervalSecs) * time.Second)
	}
}

func (fwp *fwProvisioningProcessor) processPending(ctx context.Context) {
	defer panicRecover("processPending: %p", fwp)

	tasks, err := fwp.taskRepo.GetTasks(models.Type_FWPropertiesProvisioning, models.TS_Pending, maxTasksPerCycle)

	if err != nil {
		logError("%s: error getting pending fw properties tasks - %v", fwProvisioningProcessorLogCode, err)
		return
	}

	logDebug("%s: retrieved %d fw properties tasks", fwProvisioningProcessorLogCode, len(tasks))

	for _, t := range tasks {
		logDebug("%s: acquiring lock %v", fwProvisioningProcessorLogCode, t.Id)
		key := fmt.Sprintf("mutex:deviceService:fwPropertiesProcessor:%v", t.Id)
		cmd := fwp.redis.SetNX(ctx, key, "", time.Duration(fwp.pollIntervalSecs)*time.Second)
		success := true
		if ok, e := cmd.Result(); e != nil && e != redis.Nil {
			logError("%s: lock failed %s", fwProvisioningProcessorLogCode, key)
		} else if ok {
			t.Status = models.TS_InProgress
			if errUpdate := fwp.taskRepo.UpdateTask(t); errUpdate != nil {
				logError("%s: locking task %s failed %v", fwProvisioningProcessorLogCode, t.Id, errUpdate)
				continue
			}

			if err = fwp.sendDefaultFwProps(ctx, t); err != nil {
				success = false
			}
		} else {
			logDebug("%s: lock already taken", fwProvisioningProcessorLogCode)
		}

		t.Status = models.TS_Completed
		if !success {
			t.Status = models.TS_Failed
		}
		if errUpdate := fwp.taskRepo.UpdateTask(t); errUpdate != nil {
			logError("%s: completing task %s failed %v", fwProvisioningProcessorLogCode, t.Id, errUpdate)
		}

		delResult := fwp.redis.Del(ctx, key)
		_, err := delResult.Result()
		if err != nil {
			logWarn("%s: error releasing lock for %s - %v", fwProvisioningProcessorLogCode, t.Id, err)
		}
	}

	logInfo("fwProvisioningProcessor: finished processing %d tasks", len(tasks))
}

func (fwp *fwProvisioningProcessor) sendDefaultFwProps(ctx context.Context, task *models.Task) error {

	defaultFirmwareValuesCache := fwp.memoizeRetrieveDefaultFirmwareValues()
	if task.MacAddress != nil && isValidMacAddress(*task.MacAddress) {
		device, err := fwp.deviceRepo.GetDevice(ctx, *task.MacAddress)
		if err != nil {
			logError("%s: failed to get device data for %v - %v", fwProvisioningProcessorLogCode, task.MacAddress, err)
			return err
		}

		if err = fwp.sendDefaultFwPropsByDevice(ctx, &device, defaultFirmwareValuesCache); err != nil {
			logError("%s: failed to send data to device %v - %v", fwProvisioningProcessorLogCode, task.MacAddress, err)
			return err
		}
	} else {
		var macAddressRegEx *regexp.Regexp = nil
		if task.MacAddress != nil && *task.MacAddress != "" {
			macRegEx, err := regexp.Compile(*task.MacAddress)
			if err != nil {
				return err
			} else {
				macAddressRegEx = macRegEx
			}
		}
		offset := 0
		limit := 500
		hasMore := true

		for hasMore {
			devices, err := fwp.deviceRepo.GetDevices(ctx, offset, limit, nil)
			if err != nil {
				return err
			}
			hasMore = len(devices.Items) == limit
			offset = offset + limit
			for _, device := range devices.Items {
				if macAddressRegEx != nil {
					if !macAddressRegEx.MatchString(*device.DeviceId) {
						continue
					}
				}
				if err = fwp.sendDefaultFwPropsByDevice(ctx, &device, defaultFirmwareValuesCache); err != nil {
					logError("%s: failed to send data to device %v - %v", fwProvisioningProcessorLogCode, task.MacAddress, err)
					continue
				}
			}
		}
	}

	return nil
}

func (fwp *fwProvisioningProcessor) sendDefaultFwPropsByDevice(ctx context.Context, device *DeviceBase,
	retrieveDefaultFirmwareValues func(string, string) ([]*DefaultFirmwareProperty, error)) error {

	macAddress := *device.DeviceId
	err := ValidateDeviceFwPropertiesCapabilities(ctx, macAddress, minFwValueFirstPairing, noFwValue)
	if err != nil {
		logWarn("%s: %v", fwProvisioningProcessorLogCode, err.Error())
		return err
	}

	pps, err := retrieveDefaultFirmwareValues(*device.Make, *device.Model)
	if err != nil {
		logError("%s: failed to get device data for %v - %v", fwProvisioningProcessorLogCode, device.DeviceId, err)
		return err
	}
	propsToSend := make(map[string]interface{})
	for _, p := range pps {
		propsToSend[p.Key] = p.Value
	}
	if err = sendPropsToDevice(ctx, *device.DeviceId, propsToSend, Dsh.SqlRepo); err != nil {
		logWarn("%s: Could not send fw properties to device %v", fwProvisioningProcessorLogCode, device.DeviceId)
		return err
	}

	return nil
}

func (fwp fwProvisioningProcessor) memoizeRetrieveDefaultFirmwareValues() func(string, string) ([]*DefaultFirmwareProperty, error) {
	type memoValue struct {
		value []*DefaultFirmwareProperty
	}
	type memoKey struct {
		deviceMake  string
		deviceModel string
	}
	history := make(map[memoKey]memoValue)
	return func(deviceMake string, deviceModel string) ([]*DefaultFirmwareProperty, error) {
		key := memoKey{deviceMake, deviceModel}
		if res, ok := history[key]; ok {
			return res.value, nil
		}
		val, err := fwp.deviceRepo.RetrieveDefaultFirmwareValues(deviceMake, deviceModel)
		if err == nil {
			history[key] = memoValue{
				val,
			}
		}
		return val, err
	}
}
