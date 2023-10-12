package main

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/pkg/errors"
)

type SyncService interface {
	SyncDevice(ctx context.Context, macAddress string, isEnterpriseAccount OptionalBool) *SyncServiceError
}

type ErrorType int

const (
	INTERNAL_ERROR           ErrorType = 1
	DEVICE_NOT_FOUND         ErrorType = 2
	BAD_REQUEST              ErrorType = 3
	DEVICE_IS_NOT_ENTERPRISE ErrorType = 4
	DEVICE_IS_NOT_SHUTOFF    ErrorType = 5
)

type SyncServiceError struct {
	error
	errorType ErrorType
}

type syncService struct {
	log               *Logger
	pubGwService      *pubGwService
	mudTaskRepository MudTaskRepository
	redis             *RedisConnection
}

func CreateSyncService(log *Logger, pubGwService *pubGwService, mudTaskRepository MudTaskRepository, redis *RedisConnection) SyncService {
	return &syncService{
		log:               log.CloneAsChild("syncService"),
		pubGwService:      pubGwService,
		mudTaskRepository: mudTaskRepository,
		redis:             redis,
	}
}

func (ss *syncService) SyncDevice(ctx context.Context, macAddress string, isEnterpriseAccount OptionalBool) *SyncServiceError {
	if !isEnterpriseAccount.HasValue {
		device, err := ss.pubGwService.getDevice(ctx, macAddress, "location(account)")
		if device == nil {
			return &SyncServiceError{
				error:     ss.log.Error("SyncDevice: unable to get deviceInfo from PubGW for device %v - Device Not found", macAddress),
				errorType: DEVICE_NOT_FOUND,
			}
		}
		if err != nil {
			return &SyncServiceError{
				error:     ss.log.Error("SyncDevice: unable to get deviceInfo from PubGW for device %v - %v", macAddress, err),
				errorType: INTERNAL_ERROR,
			}
		}
		if !strings.EqualFold(device.Location.Account.Type, AT_Enterprise) {
			msg := fmt.Sprintf("SyncDevice: Device %v is not part of an enterprise account", macAddress)
			ss.log.Info(msg)
			return &SyncServiceError{
				error:     errors.New(msg),
				errorType: DEVICE_IS_NOT_ENTERPRISE,
			}
		}
	} else if isEnterpriseAccount.Value == false {
		msg := fmt.Sprintf("SyncDevice: Device %v is not part of an enterprise account", macAddress)
		ss.log.Info(msg)
		return &SyncServiceError{
			error:     errors.New(msg),
			errorType: DEVICE_IS_NOT_ENTERPRISE,
		}
	}

	ss.log.Debug("SyncDevice: acquiring lock")
	key := fmt.Sprintf("mutex:floEnterpriseService:addSyncDeviceTask:%v", macAddress)
	lockAcquired, err := ss.redis.SetNX(key, "", 300)
	if err != nil {
		return &SyncServiceError{
			error:     ss.log.Error("SyncDevice: error acquiring lock - %v", err),
			errorType: INTERNAL_ERROR,
		}
	}
	if !lockAcquired {
		ss.log.Trace("SyncDevice: lock was acquired by another instance")
		return nil
	}

	ss.createPendingTaskByType(ctx, Type_DefaultSettings, macAddress)
	ss.createPendingTaskByType(ctx, Type_FWProperties, macAddress)

	_, err = ss.redis.Delete(key)
	if err != nil {
		return &SyncServiceError{
			error:     ss.log.Warn("SyncDevice: error releasing lock - %v", err),
			errorType: INTERNAL_ERROR,
		}
	}
	return nil
}

func (ss *syncService) createPendingTaskByType(ctx context.Context, taskType MudTaskType, macAddress string) {
	tasks, err := ss.mudTaskRepository.GetTasks(ctx,
		TaskFilter{
			Type:       taskType,
			Status:     []TaskStatus{TS_Pending, TS_InProgress},
			MacAddress: macAddress,
		})
	if err != nil {
		ss.log.Warn("createPendingTaskByType: error getting tasks - %v", err)
		return
	}

	if len(tasks) > 0 {
		ss.log.Warn("createPendingTaskByType: device %v was NOT queued for task %v, as it is already in pending/in-progress state", macAddress, taskType)
	} else {
		uuid, _, _ := newUuid()
		task := Task{
			Id:         uuid,
			MacAddress: macAddress,
			Type:       taskType,
			Status:     TS_Pending,
			CreatedAt:  time.Now(),
			UpdatedAt:  time.Now(),
		}
		_, err = ss.mudTaskRepository.InsertTask(ctx, &task)
		if err != nil {
			ss.log.Error("createPendingTaskByType: unable to create task for device %v - %v", macAddress, err)
			return
		}

		ss.log.Info("createPendingTaskByType: device %v successfully queued as a pending task %v", macAddress, taskType)
	}
}
