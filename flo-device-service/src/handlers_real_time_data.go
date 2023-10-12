package main

import (
	"fmt"
	"strconv"
)

func ToRealTimeData(telemetryCache map[string]string) (DeviceRealTime, error) {
	var err error
	stringToFloatConversionErrMsg := "failed to convert value %s of key %s to float64"
	noKeyErrMsg := "failed retrieve value for key %s"

	psiKey := "tlr_psi"
	tempFKey := "tlr_tempf"
	rssiKey := "tlr_rssi"
	gpmKey := "tlr_gpm"
	systemModeKey := "tlr_mode"
	valveStateKey := "tlr_valve"
	tsKey := "tlr_date"
	macAddressKey := "macAddress"

	macAddress, ok := telemetryCache[macAddressKey]
	if !ok || macAddress == EmptyString {
		return DeviceRealTime{}, fmt.Errorf(noKeyErrMsg, macAddressKey)
	}

	var psi float64 = 0
	pressureStr, ok := telemetryCache[psiKey]
	if ok && pressureStr != EmptyString {
		psi, err = strconv.ParseFloat(pressureStr, 64)
		if err != nil {
			return DeviceRealTime{}, fmt.Errorf(stringToFloatConversionErrMsg, pressureStr, psiKey)
		}
	} else {
		return DeviceRealTime{}, fmt.Errorf(noKeyErrMsg, psiKey)
	}

	var tempF float64 = 0
	tempFStr, ok := telemetryCache[tempFKey]
	if ok && tempFStr != EmptyString {
		tempF, err = strconv.ParseFloat(tempFStr, 64)
		if err != nil {
			return DeviceRealTime{}, fmt.Errorf(stringToFloatConversionErrMsg, tempFStr, tempFKey)
		}
	} else {
		return DeviceRealTime{}, fmt.Errorf(noKeyErrMsg, tempFKey)
	}

	var rssi float64 = 0
	rssiStr, ok := telemetryCache[rssiKey]
	if ok && rssiStr != EmptyString {
		rssi, err = strconv.ParseFloat(rssiStr, 64)
		if err != nil {
			return DeviceRealTime{}, fmt.Errorf(stringToFloatConversionErrMsg, rssiStr, rssiKey)
		}
	} else {
		return DeviceRealTime{}, fmt.Errorf(noKeyErrMsg, rssiKey)
	}

	var gpm float64 = 0
	gpmStr, ok := telemetryCache[gpmKey]
	if ok && gpmStr != EmptyString {
		gpm, err = strconv.ParseFloat(gpmStr, 64)
		if err != nil {
			return DeviceRealTime{}, fmt.Errorf(stringToFloatConversionErrMsg, gpmStr, gpmKey)
		}
	} else {
		return DeviceRealTime{}, fmt.Errorf(noKeyErrMsg, gpmKey)
	}

	var systemMode = 0
	systemModeStr, ok := telemetryCache[systemModeKey]
	if ok && systemModeStr != EmptyString {
		systemMode, err = strconv.Atoi(systemModeStr)
		if err != nil {
			return DeviceRealTime{}, fmt.Errorf(stringToFloatConversionErrMsg, systemModeStr, systemModeKey)
		}
	} else {
		return DeviceRealTime{}, fmt.Errorf(noKeyErrMsg, systemModeKey)
	}

	var valveState = 0
	valveStateStr, ok := telemetryCache[valveStateKey]
	if ok && valveStateStr != EmptyString {
		valveState, err = strconv.Atoi(valveStateStr)
		if err != nil {
			return DeviceRealTime{}, fmt.Errorf(stringToFloatConversionErrMsg, valveStateStr, valveStateKey)
		}
	} else {
		return DeviceRealTime{}, fmt.Errorf(noKeyErrMsg, valveStateKey)
	}

	valveStateFinal := valveIntToString(int(valveState))

	ts, ok := telemetryCache[tsKey]
	if !ok || ts == EmptyString {
		return DeviceRealTime{}, fmt.Errorf(noKeyErrMsg, tsKey)
	}

	deviceRealTimeData := DeviceRealTime{
		DeviceId: macAddress,
		Telemetry: map[string]interface{}{
			"current": map[string]interface{}{
				"gpm":     gpm,
				"tempF":   tempF,
				"psi":     psi,
				"updated": ts,
			},
		},
		Connectivity: map[string]interface{}{
			"rssi": rssi,
		},
		ValveState: map[string]interface{}{
			"lastKnown": valveStateFinal,
		},
		SystemMode: map[string]interface{}{
			"lastKnown": mapNumericToLabelSystemMode(systemMode),
		},
	}

	return deviceRealTimeData, nil
}

func mapNumericToLabelSystemMode(mode int) string {
	label, ok := numericToLabelSystemMode[mode]
	if !ok {
		label = numericToLabelSystemMode[0]
	}
	return label
}
