package main

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/pkg/errors"
)

const (
	lteSyncLogCode                                   = "lteSyncProcessor"
	etagKey                                          = "etag:floEnterpriseService:lteSyncProcessor"
	ENVFLO_LTE_PROCESSOR_POLL_INTERVAL_HOURS         = "FLO_LTE_PROCESSOR_POLL_INTERVAL_HOURS"
	ENVFLO_LTE_PROCESSOR_POLL_INTERVAL_HOURS_DEFAULT = 24
)

type lteSyncProcessor struct {
	log              *Logger
	mudRepository    MudTaskRepository
	redis            *RedisConnection
	pubGwService     *pubGwService
	deviceService    *deviceService
	attSvcClient     *AttSvcClient
	pollIntervalSecs int
	isOpen           int32
	isRunning        int32
}

func NewLTESyncProcessor(log *Logger, mudRepository MudTaskRepository, redis *RedisConnection,
	deviceService *deviceService, pubGWService *pubGwService, attSvcClient *AttSvcClient) Processor {
	pollInterval, err := strconv.Atoi(getEnvOrDefault("FLO_LTE_PROCESSOR_POLL_INTERVAL_HOURS",
		strconv.Itoa(ENVFLO_LTE_PROCESSOR_POLL_INTERVAL_HOURS_DEFAULT)))
	if err != nil {
		pollInterval = ENVFLO_LTE_PROCESSOR_POLL_INTERVAL_HOURS_DEFAULT
	}

	return createLTESyncProcessor(log, SECS_1_HOUR*pollInterval, mudRepository, redis, deviceService, pubGWService, attSvcClient)
}

func createLTESyncProcessor(log *Logger, pollIntervalSecs int, mudRepository MudTaskRepository, redis *RedisConnection,
	deviceService *deviceService, pubGWService *pubGwService, attSvcClient *AttSvcClient) Processor {
	return &lteSyncProcessor{
		log:              log.CloneAsChild(lteSyncLogCode),
		pollIntervalSecs: pollIntervalSecs,
		mudRepository:    mudRepository,
		redis:            redis,
		pubGwService:     pubGWService,
		deviceService:    deviceService,
		attSvcClient:     attSvcClient,
	}
}

func (lp *lteSyncProcessor) Open() {
	if atomic.CompareAndSwapInt32(&lp.isOpen, 0, 1) {
		lp.log.Debug("Open: begin")
		go lp.runProcessor()
	} else {
		lp.log.Warn("Open: already opened")
	}
}

func (lp *lteSyncProcessor) Close() {
	safelyCloseProcessor(&lp.isOpen, &lp.isRunning, lp.log)
}

func (lp *lteSyncProcessor) runProcessor() {
	defer panicRecover(lp.log, "runProcessor panic: %p", lp)

	autoResetScheduler(&lp.isOpen, lp.pollIntervalSecs, func() {
		ctx := context.Background()
		lp.log.Trace("runProcessor: processing devices with pending tasks")
		go lp.processPendingDevices(ctx)
	})
}

func (lp *lteSyncProcessor) processPendingDevices(ctx context.Context) {
	defer panicRecover(lp.log, "processPendingDevices panic: %p", lp)

	atomic.StoreInt32(&lp.isRunning, 1)
	defer func() {
		atomic.StoreInt32(&lp.isRunning, 0)
	}()

	key := "mutex:floEnterpriseService:lteSyncProcessor"
	lockAcquired, err := processorAcquireLock(lp.redis, key, lp.pollIntervalSecs)
	if err != nil {
		lp.log.Warn("processPendingDevices: error acquiring lock - %v", err)
		return
	}

	if !lockAcquired {
		lp.log.Trace("processPendingDevices: lock was acquired by another instance")
		return
	}

	err = lp.processLTEDevicePairing(ctx)

	if err != nil {
		lp.log.Warn("processPendingDevices: error %v", err)
	}
}

func (lp *lteSyncProcessor) processLTEDevicePairing(ctx context.Context) error {
	allDeviceHeaders := make([]DeviceApi, 0)
	hasMore := true
	offset := 0
	for hasMore {
		allDevices, err := lp.deviceService.getAllDevices(ctx, true, offset)
		if err != nil {
			return errors.Wrapf(err, "processLTEDevicePairing: error getting devices from service")
		}
		allDeviceHeaders = append(allDeviceHeaders, allDevices.Items...)
		hasMore = allDevices.Meta.Total > allDevices.Meta.Offset && len(allDevices.Items) > 0
		offset = len(allDeviceHeaders)
	}

	lp.log.Info("processLTEDevicePairing: processing data from %v devices", len(allDeviceHeaders))
	iccids := make(map[string]AttSvcBulkUploadRow)
	for _, deviceHeader := range allDeviceHeaders {
		device, err := lp.pubGwService.getDevice(ctx, deviceHeader.MacAddress, "location(account(owner))")
		if err != nil {
			lp.log.Warn("processLTEDevicePairing: error getting device %v from device service", deviceHeader.MacAddress)
		}

		if device.Location.Account == nil || device.Connectivity.LTE == nil {
			lp.log.Warn("processLTEDevicePairing: error getting device information for %v", deviceHeader.MacAddress)
		}

		iccid := device.Connectivity.LTE.ICCID
		owner := device.Location.Account.Owner
		accountId := device.Location.Account.Id

		if iccid == "" || owner == nil {
			lp.log.Warn("processLTEDevicePairing: device %v does not have an owner or LTE device ID", deviceHeader.MacAddress)
		}

		iccids[iccid] = AttSvcBulkUploadRow{
			EndConsumerId:             accountId,
			EndConsumerEmail:          owner.Email,
			EndConsumerPhone:          owner.PhoneMobile,
			EndConsumerFullName:       fmt.Sprintf("%s %s", owner.FirstName, owner.LastName),
			EndConsumerBillingAddress: device.Location.Address,
			EndConsumerBillingCity:    device.Location.City,
			EndConsumerBillingState:   device.Location.State,
		}
	}
	hash := lp.computeHash(iccids)
	if len(iccids) > 0 && lp.isNewUpload(hash) {
		err := lp.attSvcClient.BulkDeviceUpload(ctx, fmt.Sprintf("flo_ec_%v_%v", hash, time.Now().UTC().Format("2006-01-02")), iccids)
		if err != nil {
			return errors.Wrapf(err, "processLTEDevicePairing: error uploading end consumer info")
		}
		if hashErr := lp.setUploadHash(hash); hashErr != nil {
			lp.log.Warn("processLTEDevicePairing: Could not update bulk hash")
		}

		lp.log.Info("processLTEDevicePairing: done processing, hash = %v", hash)
	} else {
		lp.log.Notice("processLTEDevicePairing: Upload not needed, skipping")
	}
	return nil
}

func (lp *lteSyncProcessor) isNewUpload(hash string) bool {
	if val, err := lp.redis.Get(etagKey); err != nil {
		return err.Error() == "redis: nil"
	} else if val != hash {
		return true
	}
	return false
}

func (lp *lteSyncProcessor) setUploadHash(hash string) error {
	if _, err := lp.redis.Set(etagKey, hash, SECS_1_WEEK); err != nil {
		return err
	}
	return nil
}

func (lp *lteSyncProcessor) computeHash(dict map[string]AttSvcBulkUploadRow) string {
	sb := &strings.Builder{}
	keys := make([]string, 0, len(dict))
	for k := range dict {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		sb.WriteString(fmt.Sprintf("%v|%v", k, dict[k]))
	}

	slug := sb.String()
	sb.Reset()

	data := md5.Sum([]byte(slug))
	return hex.EncodeToString(data[:])
}
