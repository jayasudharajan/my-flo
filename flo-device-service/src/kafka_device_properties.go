package main

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strings"
	"time"
)

func unmarshalDevicePropertiesPayload(requestPayload []byte) (DeviceInternal, error) {
	var fwPropertiesRaw FwPropertiesRaw
	err := json.Unmarshal(requestPayload, &fwPropertiesRaw)
	if err != nil {
		logError("unmarshalDevicePropertiesPayload: failed to bind device kafka fwPropertiesRaw with internal device properties struct")
		return DeviceInternal{}, err
	}

	fwVersion := undefined
	systemMode := undefined
	valveState := undefined

	// FwVersion is the only fwProperties property to become a first class citizen of the DeviceBase struct
	if fwPropertiesRaw.Properties != nil {
		fwVersionI, ok := (*fwPropertiesRaw.Properties)[FwVersionInternalPropertiesKey]
		if ok {
			fwVersion = fwVersionI.(string)
		}

		systemModeI, ok := (*fwPropertiesRaw.Properties)[SystemModeInternalPropertiesKey]
		if ok {
			systemMode = convertSystemMode(systemModeI)
		}

		valveState = parseFwPropertiesForValveState((*fwPropertiesRaw.Properties))
	}

	connected := true

	// map FwPropertiesRaw to DeviceBase model
	device := DeviceInternal{
		DeviceId:        fwPropertiesRaw.DeviceId,
		IsConnected:     &connected,
		FwVersion:       &fwVersion,
		SystemMode:      &systemMode,
		ValveState:      &valveState,
		Created:         &time.Time{},
		LastHeardFrom:   &time.Time{},
		Updated:         &time.Time{},
		FwPropertiesRaw: &fwPropertiesRaw,
	}
	return device, nil
}

const PROPERTY_REASON_GET string = "get"
const PROPERTY_REASON_POWERUP string = "powerup"
const PROPERTY_REASON_HEARTBEAT string = "heartbeat"
const PROPERTY_REASON_CONNECTED string = "connected" // This applies to both a new device pairing as well as when the user changes the WiFi SSID from the APP.

func processDeviceProperties(ctx context.Context, device DeviceInternal) error {
	// Execute these
	propReason := ""
	if device.FwPropertiesRaw.Reason != nil {
		propReason = *device.FwPropertiesRaw.Reason
	}

	devId := ""
	if device.DeviceId != nil {
		devId = *device.DeviceId
	}
	realTimeData := make(map[string]interface{})
	realTimeData[DeviceIdKey] = devId

	if strings.EqualFold(propReason, PROPERTY_REASON_GET) ||
		strings.EqualFold(propReason, PROPERTY_REASON_POWERUP) ||
		strings.EqualFold(propReason, PROPERTY_REASON_HEARTBEAT) {

		block := time.Now()
		logDebug("processDeviceProperties: DeviceId %v -> %v", device.DeviceId, propReason)
		// Use properties to set the variables
		SetLastKnownSystemMode(ctx, devId, *(device.SystemMode))
		SetLastKnownValveState(ctx, devId, *(device.ValveState))
		if verifySystemMode(ctx, devId, "properties:"+propReason, strings.EqualFold(propReason, PROPERTY_REASON_POWERUP)) {
			go _recon.MarkSynced(ctx, devId)
		}
		logTrace("processDeviceProperties: DeviceId %v -> %v | Took %vms", device.DeviceId, propReason, time.Since(block).Milliseconds())
	} else {
		logDebug("processDeviceProperties: DeviceId %v", device.DeviceId)
	}

	if device.FwPropertiesRaw != nil && device.FwPropertiesRaw.Properties != nil {
		if val, ok := (*device.FwPropertiesRaw.Properties)["alarm_shutoff_time_epoch_sec"]; ok && val != nil {
			tempTime, ok := val.(float64)
			if ok {
				unixTime := int64(tempTime)
				if unixTime < 0 || unixTime > math.MaxInt32 {
					unixTime = 0
				}
				dt := time.Unix(unixTime, 0)

				alarmShutoffId := ""
				incidentId, ok := (*device.FwPropertiesRaw.Properties)["alarm_shutoff_id"]
				if ok && incidentId != nil {
					alarmShutoffId = fmt.Sprintf("%v", incidentId)
				}

				realTimeData["shutoff"] = map[string]interface{}{
					"scheduledAt": dt.UTC(),
					"alertId":     alarmShutoffId,
				}
			}
		}
	}
	if len(realTimeData) > 1 && len(devId) > 0 {
		go asyncUpdateRealTimeData(ctx, devId, realTimeData)
	}

	upDt := time.Now()
	err := postgresRepo.UpsertDevice(ctx, device)
	if err != nil {
		logError("processDeviceProperties: failed to save device properties to PGDB for Device %v", devId)
		return err
	} else {
		logDebug("processDeviceProperties: Successful save for %v | took %vms", devId, time.Since(upDt).Milliseconds())
	}
	return nil
}
