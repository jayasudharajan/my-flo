package main

import "strings"

func CreateDeviceMappers(dv *Device, alerts []*Incident) []DeviceMapper {
	dms := make([]DeviceMapper, 0, 2)
	if strings.Index(dv.DeviceType, swsTypePrefix) == 0 {
		var (
			valveMap  = CreateValveMapper(dv)
			sensorMap = CreateSensorMapper(dv, alerts)
		)
		dms = append(dms, valveMap, sensorMap)
	} else if strings.Index(dv.DeviceType, swdTypePrefix) == 0 {
		var (
			detectorMap = CreateSensorMapper(dv, alerts)
		)
		dms = append(dms, detectorMap)
	}
	return dms
}

type DeviceMapper interface {
	Id() string
	ToHgDevice() (*HgDevice, error)
	ToHgStat(seq SeqGen) HgStat
}
