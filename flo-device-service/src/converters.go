package main

import (
	"time"
)

const reason = "api"

// MapDeviceToDeviceInternal is the mapper function to map DeviceBase to DeviceInternal
func (d *DeviceBase) MapDeviceToDeviceInternal() DeviceInternal {
	var fwProperties map[string]interface{}

	if d.FwProperties != nil {
		fwProperties = *(d.FwProperties)
	} else {
		fwProperties = make(map[string]interface{})
	}

	var muteAudioUntil *time.Time = nil
	if d.Audio != nil && d.Audio.SnoozeTo != nil {
		muteAudioUntil = d.Audio.SnoozeTo
	}

	r := reason
	t := time.Now().UTC().Unix()

	res := DeviceInternal{
		DeviceId:      d.DeviceId,
		IsConnected:   d.IsConnected,
		FwVersion:     d.FwVersion,
		Created:       d.Created,
		LastHeardFrom: d.LastHeardFrom,
		Updated:       d.Updated,
		FwPropertiesRaw: &FwPropertiesRaw{
			Id:         nil,
			RequestId:  nil,
			DeviceId:   d.DeviceId,
			Timestamp:  &t,
			Reason:     &r,
			Properties: &fwProperties,
		},
		Make:               d.Make,
		Model:              d.Model,
		HardwareThresholds: d.HardwareThresholds,
		MuteAudioUntil:     muteAudioUntil,
		LatestFwInfo:       d.LatestFwInfo,
		ComponentHealth:    d.ComponentHealth,
		ValveStateMeta:     d.ValveStateMeta,
	}
	if d.FwUpdateReq != nil && len(d.FwUpdateReq.Meta) != 0 {
		res.FwUpdateReq = &FwUpdateReq{
			Meta: d.FwUpdateReq.Meta, //only map meta, the rest is already in FwPropertiesRaw
		}
	}
	return res
}

// MapDeviceInternalToDeviceBase is the mapper function to map DeviceInternal to DeviceBase
func (d *DeviceInternal) MapDeviceInternalToDeviceBase() DeviceBase {
	var audio *Audio = nil

	if d.MuteAudioUntil.After(time.Unix(0, 0)) {
		var snoozeSeconds int64 = 0
		now := time.Now()
		if d.MuteAudioUntil.After(now) {
			snoozeSeconds = int64(d.MuteAudioUntil.Sub(now).Seconds())
		}

		audio = &Audio{
			SnoozeTo:      d.MuteAudioUntil,
			SnoozeSeconds: &snoozeSeconds,
		}
	}

	return DeviceBase{
		DeviceId:           d.DeviceId,
		IsConnected:        d.IsConnected,
		IsMobile:           d.IsMobile,
		FwVersion:          d.FwVersion,
		Created:            d.Created,
		LastHeardFrom:      d.LastHeardFrom,
		Updated:            d.Updated,
		FwProperties:       d.FwPropertiesRaw.Properties,
		Make:               d.Make,
		Model:              d.Model,
		HardwareThresholds: d.HardwareThresholds,
		Audio:              audio,
		LatestFwInfo:       d.LatestFwInfo,
		ComponentHealth:    d.ComponentHealth,
		FwUpdateReq:        d.FwUpdateReq,
		ValveStateMeta:     d.ValveStateMeta,
	}
}

// MaOnboardingLogExternalToOnboardingLog is the mapper function to map OnboardingLogExternal to OnboardingLog
func (ol *OnboardingLogExternal) MapOnboardingLogExternalToOnboardingLog() OnboardingLog {

	res := OnboardingLog{
		Id:                      ol.Id,
		MacAddress:              ol.MacAddress,
		Created:                 ol.Created,
		UpdatedLastTime:         ol.UpdatedLastTime,
		Event:                   ol.Event,
		DeviceModel:             ol.DeviceModel,
		DeviceType:              ol.DeviceType,
		IsPaired:                ol.IsPaired,
		LocationId:              ol.LocationId,
		Nickname:                ol.Nickname,
		PuckConfiguredAt:        ol.PuckConfiguredAt,
		RevertMinutes:           ol.RevertMinutes,
		RevertMode:              ol.RevertMode,
		RevertScheduledAt:       ol.RevertScheduledAt,
		ShouldInheritSystemMode: ol.ShouldInheritSystemMode,
		TargetSystemMode:        ol.TargetSystemMode,
		TargetValveState:        ol.TargetValveState,
	}

	return res
}

// MapOnboardingLogToOnboardingLogExternal is the mapper function to map OnboardingLogExternal to OnboardingLog
func (ol *OnboardingLog) MapOnboardingLogToOnboardingLogExternal() OnboardingLogExternal {
	res := OnboardingLogExternal{
		Id:                      ol.Id,
		MacAddress:              ol.MacAddress,
		Created:                 ol.Created,
		UpdatedLastTime:         ol.UpdatedLastTime,
		Event:                   ol.Event,
		DeviceModel:             ol.DeviceModel,
		DeviceType:              ol.DeviceType,
		IsPaired:                ol.IsPaired,
		LocationId:              ol.LocationId,
		Nickname:                ol.Nickname,
		PuckConfiguredAt:        ol.PuckConfiguredAt,
		RevertMinutes:           ol.RevertMinutes,
		RevertMode:              ol.RevertMode,
		RevertScheduledAt:       ol.RevertScheduledAt,
		ShouldInheritSystemMode: ol.ShouldInheritSystemMode,
		TargetSystemMode:        ol.TargetSystemMode,
		TargetValveState:        ol.TargetValveState,
	}

	return res
}
