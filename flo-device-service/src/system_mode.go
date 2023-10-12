package main

import (
	"context"
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	ot "github.com/opentracing/opentracing-go"
)

const (
	SYSTEM_MODE_UNKNOWN string = "unknown"
	SYSTEM_MODE_HOME    string = "home"
	SYSTEM_MODE_AWAY    string = "away"
	SYSTEM_MODE_SLEEP   string = "sleep"
)

var numericToLabelSystemMode = map[int]string{
	0: SYSTEM_MODE_UNKNOWN,
	//1: "unused",
	2: SYSTEM_MODE_HOME,
	3: SYSTEM_MODE_AWAY,
	//4: "unused",
	5: SYSTEM_MODE_SLEEP,
	//6: "learning",
}

type KafkaSystemModeModel struct {
	Id            string `json:"id"`
	DeviceId      string `json:"did"`
	Timestamp     int64  `json:"ts"`
	State         int    `json:"st"`
	PreviousState int    `json:"pst"`
	StateName     string `json:"sn"`
}

func (o *KafkaSystemModeModel) StateString() string {
	if o == nil {
		return ""
	}
	return convertSystemMode(o.State)
}
func (o *KafkaSystemModeModel) PreviousStateString() string {
	if o == nil {
		return ""
	}
	return convertSystemMode(o.State)
}

func UnmarshalKafkaSystemModeData(data []byte) *KafkaSystemModeModel {
	if len(data) < 2 {
		return nil
	}

	rv := new(KafkaSystemModeModel)
	err := json.Unmarshal(data, &rv)
	if err != nil {
		return nil
	}
	return rv
}

func ProcessSystemModeKafkaMessage(ctx context.Context, payload []byte) {
	x := UnmarshalKafkaSystemModeData(payload)
	if x == nil {
		return
	}

	SetLastKnownSystemMode(ctx, x.DeviceId, x.StateString())
}

func SetLastKnownSystemMode(ctx context.Context, deviceId string, systemMode string) {
	if len(deviceId) != 12 || !isSystemModeValid(systemMode) {
		logError("SetLastKnownSystemMode: Device: %v State: %v. Database not updated.", deviceId, systemMode)
		return
	}
	funcSpan, ctx1 := ot.StartSpanFromContext(ctx, "SetLastKnownSystemMode")
	defer funcSpan.Finish()

	// Clean the ID
	deviceId = strings.TrimSpace(strings.ToLower(deviceId))
	wg := new(sync.WaitGroup)

	// Set the value in Redis
	wg.Add(1)
	go func(c context.Context, w *sync.WaitGroup, d string, s string) {
		defer w.Done()
		ok, err := redisRepo.SetDeviceCachedData(c, d, map[string]interface{}{
			"systemMode.lastKnown": s,
		})

		if err != nil {
			logError("SetLastKnownSystemMode: REDIS: Device: %v Mode: %v Error: %v", d, s, err.Error())
		}
		if ok {
			logDebug("SetLastKnownSystemMode: REDIS: SET Device: %v Mode: %v", d, s)
		} else {
			logWarn("SetLastKnownSystemMode: REDIS: NOTSET Device: %v Mode: %v", d, s)
		}
	}(ctx1, wg, deviceId, systemMode)

	// Set the value in Firestore
	wg.Add(1)
	go func(c context.Context, w *sync.WaitGroup, d string, s string) {
		defer w.Done()
		err := UpdateFirestore(c, d, map[string]interface{}{
			"deviceId": d,
			"systemMode": map[string]interface{}{
				"lastKnown": s,
			},
		})

		if err != nil {
			logError("SetLastKnownSystemMode: FW: Device: %v Mode: %v Error: %v", d, s, err.Error())
		} else {
			logDebug("SetLastKnownSystemMode: FW: SET Device: %v Mode: %v", d, s)
		}
	}(ctx1, wg, deviceId, systemMode)

	// Set the value in Database
	wg.Add(1)
	go func(c context.Context, w *sync.WaitGroup, d string, s string) {
		defer w.Done()
		err := Dsh.SqlRepo.SetLastMode(c, d, s)

		if err != nil {
			logError("SetLastKnownSystemMode: PGDB: Device: %v Mode: %v Error: %v", d, s, err.Error())
		} else {
			logDebug("SetLastKnownSystemMode: PGDB: SET Device: %v Mode: %v", d, s)
		}
	}(ctx1, wg, deviceId, systemMode)

	wg.Wait()
}

func isSystemModeValid(mode string) bool {
	if mode == "" {
		return false
	}
	switch strings.ToLower(mode) {
	case SYSTEM_MODE_HOME, SYSTEM_MODE_AWAY, SYSTEM_MODE_SLEEP:
		return true
	default:
		return false
	}
}

// NOTE: before the change, this function used to only allow SYSTEM_MODE_HOME, SYSTEM_MODE_AWAY
func allowSystemModeTarget(target string) bool {
	return isSystemModeValid(target)
}

func isUnknownValue(v string) bool {
	if v == "" {
		return true
	}
	v = strings.ToLower(v)
	return v == undefined || v == unknownKey
}

func convertSystemMode(systemModeStateI interface{}) string {
	systemModeStateFloat, err := strconv.ParseFloat(fmt.Sprintf("%v", systemModeStateI), 64)
	if err != nil {
		logError("failed to convert system mode %v", systemModeStateI)
	}

	systemMode, ok := numericToLabelSystemMode[int(systemModeStateFloat)]
	if !ok {
		systemMode = unknownKey
	}
	return systemMode
}

func extractDt(dts string) time.Time {
	dt, _ := time.Parse(time.RFC3339, dts)
	return dt
}

func setSystemModeTarget(ctx context.Context, id string, level string, target string, context SystemModeReconciliation) bool {
	if isUnknownValue(id) || isUnknownValue(level) || isUnknownValue(target) {
		logWarn("RSM setSystemModeTarget: invalid vars. id: %v, level: %v, target: %v", id, level, target)
		return false
	}
	var devLv, locLv bool
	if devLv, locLv = strings.EqualFold(level, "devices"), strings.EqualFold(level, "locations"); !(devLv || locLv) {
		logWarn("RSM setSystemModeTarget: invalid level: '%v'", level)
		return false
	}
	if !allowSystemModeTarget(target) {
		logInfo("RSM setSystemModeTarget: will not reconcile %v mode for id %s to %v", level, id, target)
		return false
	}
	if strings.EqualFold(target, SYSTEM_MODE_SLEEP) { //additional sleep check
		var dt time.Time
		if devLv && context.Device.HasRevertTime() {
			dt = context.Device.RevertTime()
		} else if context.Location.HasRevertTime() {
			dt = context.Location.RevertTime()
		} else if !context.Device.IsLocked && strings.EqualFold(context.Device.LastKnown, SYSTEM_MODE_SLEEP) { //no revert time & not locked
			var br = false                                                                                     //take device out of forever sleep
			if context.Device.ShouldInherit && strings.EqualFold(context.Location.Target, SYSTEM_MODE_SLEEP) { //reset location to home
				logInfo("RSM setSystemModeTarget: RESET location %v to HOME for %v", context.LocationId, context.Icd)
				br = SetTargetSystemMode(ctx, context.LocationId, "locations", SYSTEM_MODE_HOME, context) //reset to home
			}
			if strings.EqualFold(context.Device.LastKnown, SYSTEM_MODE_SLEEP) { //reset device to home
				logInfo("RSM setSystemModeTarget: RESET device %v to HOME", context.Icd)
				br = SetTargetSystemMode(ctx, context.Icd, "devices", SYSTEM_MODE_HOME, context) //reset to home
			}
			return br
		}

		const maxRevert = time.Minute * -61
		if dt.Year() < 2000 { //bad exp, don't do it
			logWarn("RSM setSystemModeTarget: bad %v revert time %v for id %v to %v", level, dt, id, target)
			return false
		} else if ttl := dt.UTC().Sub(time.Now().UTC()); ttl < maxRevert { //less than 5min left, don't do it
			logWarn("RSM setSystemModeTarget: bad %v revert time %v for id %v to %v | less than %v ttl=%v", level, dt, id, target, maxRevert, ttl)
			return false
		}
	}
	return SetTargetSystemMode(ctx, id, level, target, context) //change mode
}

func getMutexVerifySystemMode(ctx context.Context, macAddress string, reason string, force bool) bool {
	key := "mutex:verifySystemMode:" + macAddress
	if force {
		Dsh.Cache.Redis.Set(ctx, key, _hostname, time.Minute)
		return true
	} else {
		cmd := Dsh.Cache.Redis.SetNX(ctx, key, _hostname, time.Minute)
		return cmd.Val()
	}
}

func isSwsV1(mac string) bool {
	if mac == "" {
		return false
	}
	mac = strings.ToLower(mac)
	return strings.Index(mac, "8cc7aa") == 0 || strings.Index(mac, "f87aef") == 0
}

// Request properties - the "get" action will trigger mode reconciliation
// This will obviously miss GEN1 devices and old firmware builds
func verifySystemMode(ctx context.Context, macAddress string, reason string, force bool) bool {
	defer panicRecover("verifySystemMode: %v force=%v | %v", macAddress, force, reason)

	if !isValidDeviceMac(macAddress) {
		logError("RSM verifySystemMode: invalid mac address %v", macAddress)
		return false
	}
	if isSwsV1(macAddress) {
		logNotice("RSM verifySystemMode: skipping v1 device mac address %v", macAddress)
	}
	if !getMutexVerifySystemMode(ctx, macAddress, reason, force) {
		logTrace("RSM verifySystemMode: %v %v throttled, not run", macAddress, reason)
		return false
	}

	// Get the current state of this device
	current, err := GetSystemModeReconciliation(ctx, macAddress)
	if err != nil {
		if _, ok := err.(*ReconRejectionError); ok {
			logNotice("RSM verifySystemMode: skipping %v %v | %v", macAddress, reason, err.Error())
		} else {
			logWarn("RSM verifySystemMode: %v %v | %v", macAddress, reason, err.Error())
		}
		return false
	}
	if isUnknownValue(current.Icd) {
		logWarn("RSM verifySystemMode: %v device not found", macAddress)
		return false
	}
	if isUnknownValue(current.LocationId) {
		logWarn("RSM verifySystemMode: %v location not found", macAddress)
		return false
	}
	current.reason = reason
	logDebug("RSM verifySystemMode: %v %v %v", macAddress, reason, toJson(current))

	// Device is locked to its own state or should not inherit, do not consider location mode at all
	if current.Device.IsLocked || !current.Device.ShouldInherit {
		logDebug("RSM verifySystemMode: only considering device info, ignoring location %v", macAddress)
		return verifyDeviceSystemModeOnly(ctx, current, macAddress)
	}

	// Everything matches, do nothing
	if strings.EqualFold(current.Location.Target, current.Device.Target) &&
		strings.EqualFold(current.Location.Target, current.Device.LastKnown) {
		// If we have a revert mode set on the location and its past it's time, lets revert back
		if ok, mode := shouldRevertSystemMode(macAddress, current.Device.IsLocked, current.Location.Target, current.Location.RevertMode, current.Location.RevertScheduledAt); ok {
			logDebug("RSM verifySystemMode: %v reverting to mode %v", macAddress, mode)
			return setSystemModeTarget(ctx, current.LocationId, "locations", mode, current)
		}
		logDebug("RSM verifySystemMode: %v in sync", macAddress)
		return false
	}

	// Location does not contain proper values, ignore
	if isUnknownValue(current.Location.Target) {
		// Invalid location should fallback to device level
		return verifyDeviceSystemModeOnly(ctx, current, macAddress)
	}

	// If we have a revert mode set on the location and its past it's time, lets revert back
	if ok, mode := shouldRevertSystemMode(macAddress, current.Device.IsLocked, current.Location.Target, current.Location.RevertMode, current.Location.RevertScheduledAt); ok {
		logDebug("RSM verifySystemMode: %v %v reverting to mode %v", macAddress, current.LocationId, mode)
		return setSystemModeTarget(ctx, current.LocationId, "locations", mode, current)
	}

	// Ensure location and device targets are the same
	if !strings.EqualFold(current.Location.Target, current.Device.Target) {
		logDebug("RSM verifySystemMode: %v %v location and device mismatch, setting mode %v", macAddress, current.LocationId, current.Location.Target)
		return setSystemModeTarget(ctx, current.Icd, "devices", current.Location.Target, current)
	}

	// Everything on location is good, make sure device is good
	logDebug("RSM verifySystemMode: fall through %v ", macAddress)
	return verifyDeviceSystemModeOnly(ctx, current, macAddress)
}

func verifyDeviceSystemModeOnly(ctx context.Context, current SystemModeReconciliation, macAddress string) bool {
	// If we have a revert mode set on the device and its past it's time, lets revert back
	if ok, mode := shouldRevertSystemMode(macAddress, current.Device.IsLocked, current.Device.Target, current.Device.RevertMode, current.Device.RevertScheduledAt); ok {
		logDebug("RSM verifyDeviceSystemModeOnly: %v reverting to mode %v", macAddress, mode)
		return setSystemModeTarget(ctx, current.Icd, "devices", mode, current)
	}

	// Only reconcile allowed modes
	if !allowSystemModeTarget(current.Device.Target) {
		logWarn("RSM verifyDeviceSystemModeOnly: %v invalid target %v", macAddress, current.Device.Target)
		return false
	}

	// Everything matches, do nothing
	if strings.EqualFold(current.Device.LastKnown, current.Device.Target) {
		// If we have a revert mode set on the device and its past it's time, lets revert back
		if ok, mode := shouldRevertSystemMode(macAddress, current.Device.IsLocked, current.Device.Target, current.Device.RevertMode, current.Device.RevertScheduledAt); ok {
			logDebug("RSM verifyDeviceSystemModeOnly: %v reverting to mode %v", macAddress, mode)
			return setSystemModeTarget(ctx, current.Icd, "devices", mode, current)
		}
		logDebug("RSM verifyDeviceSystemModeOnly: %v in sync", macAddress)
		return false
	}

	// We do not know the last known property, request a sync - this only works for FW v3.6+. GEN1 and older need a fix
	if isUnknownValue(current.Device.LastKnown) {
		logDebug("RSM verifyDeviceSystemModeOnly: %v refreshing lastKnown using properties", macAddress)
		return PublishToFwPropsMqttTopic(ctx, macAddress, QOS_1, nil, "get")
	}

	if current.Device.IsLocked {
		if !strings.EqualFold(current.Device.LastKnown, SYSTEM_MODE_SLEEP) {
			logWarn("RSM verifyDeviceSystemModeOnly: NONE_SLEEP_LOCKED device!!! %v", macAddress)
		} else {
			logDebug("RSM verifyDeviceSystemModeOnly: SKIPPING forced sleep device %v", macAddress)
		}
		return false
	}
	if !strings.EqualFold(current.Device.LastKnown, current.Device.Target) {
		logDebug("RSM verifyDeviceSystemModeOnly: %v target and lastKnown mismatch, setting mode to %v", macAddress, current.Device.Target)
		return setSystemModeTarget(ctx, current.Icd, "devices", current.Device.Target, current)
	}
	return false
}

func shouldRevertSystemMode(macAddress string, isLocked bool, currentTarget string, revertMode string, revertTimeString string) (bool, string) {
	// Invalid revert mode
	if !allowSystemModeTarget(revertMode) {
		logDebug("shouldRevertSystemMode: invalid mode %v %v %v %v", macAddress, currentTarget, revertMode, revertTimeString)
		return false, ""
	}

	// Match, do nothing
	if strings.EqualFold(currentTarget, revertMode) {
		logDebug("shouldRevertSystemMode: match target %v %v %v %v", macAddress, currentTarget, revertMode, revertTimeString)
		return false, ""
	}

	// Invalid revert time
	if isUnknownValue(revertTimeString) {
		logDebug("shouldRevertSystemMode: invalid time %v %v %v %v", macAddress, currentTarget, revertMode, revertTimeString)
		return false, ""
	}

	if dt := extractDt(revertTimeString); time.Now().UTC().After(dt.UTC()) { // Parse and compare to now in UTC
		if isLocked && strings.EqualFold(currentTarget, SYSTEM_MODE_SLEEP) { //Don't allow mode revert from sleep when locked. SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-3562
			logDebug("shouldRevertSystemMode: isLocked, NOT reverting %v %v %v %v", macAddress, currentTarget, revertMode, revertTimeString)
			return false, ""
		}
		logDebug("shouldRevertSystemMode: revert needed %v %v %v %v", macAddress, currentTarget, revertMode, revertTimeString)
		return true, revertMode
	}

	logDebug("shouldRevertSystemMode: future %v %v %v %v", macAddress, currentTarget, revertMode, revertTimeString)
	return false, ""
}

var (
	_sleepReconSchedule = time.Minute * 10 //run every duration
	_minSleepReconTTL   = time.Minute * 5
)

func systemModeReconciliationWorker(ctx context.Context) {
	nextRun := time.Now().Truncate(time.Minute).Add(time.Minute)
	logInfo("systemModeReconciliationWorker: Next run %v", nextRun.Format(time.RFC3339))

	for {
		if time.Now().Before(nextRun) {
			time.Sleep(time.Second)
			continue
		}

		nextRun = time.Now().Truncate(_sleepReconSchedule).Add(_sleepReconSchedule)
		logInfo("systemModeReconciliationWorker: Start")
		sleepModeReconciliation(ctx)
		logInfo("systemModeReconciliationWorker: Done. Next run %v", nextRun.Format(time.RFC3339))
	}
}

const MODE_VERIFY_SCHEDULED = "scheduled"

func sleepModeReconciliation(ctx context.Context) error {
	defer panicRecover("sleepModeReconciliation")

	var ( // Get a list of all devices considered online
		start     = time.Now()
		query     = `SELECT device_id FROM devices WHERE mode_latest='sleep' AND is_connected=true AND model like 'flo_device_%';`
		rows, err = _pgdb.QueryContext(ctx, query)
	)
	if err != nil {
		return logError("sleepModeReconciliation: %v", err.Error())
	}
	defer rows.Close()

	macList := make([]string, 0)
	for rows.Next() {
		tmp := ""
		rows.Scan(&tmp)
		if len(tmp) == 12 && !isSwsV1(tmp) {
			macList = append(macList, strings.ToLower(tmp))
		}
	}
	queryDur := time.Since(start)
	sort.Strings(macList)
	logDebug("sleepModeReconciliation: starting to reconcile %v devices | took %vms", len(macList), queryDur.Milliseconds())

	var (
		skipped  = 0
		reqCount = 0
		key      string
		ttl      = _sleepReconSchedule / 3
	)
	if ttl < _minSleepReconTTL {
		ttl = _minSleepReconTTL
	}
	for _, mac := range macList {
		// Grab mutex - if we can't, move to the next one
		key = "mutex:ModeRecon:" + mac
		if ok := _redis.SetNX(ctx, key, _hostname, ttl); !ok.Val() {
			skipped++
			continue
		}

		// Request properties - the "get" action will trigger mode reconciliation
		// This will obviously miss GEN1 devices and old firmware builds
		verifySystemMode(ctx, mac, MODE_VERIFY_SCHEDULED, false)
		reqCount++

		// Don't do this too quickly, we don't want to flood the system
		time.Sleep(time.Millisecond * 444)
	}
	logInfo("sleepModeReconciliation: processed %v, skipped %v, total %v, took %v", reqCount, skipped, len(macList), time.Since(start))
	return nil
}
