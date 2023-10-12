package main

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type valveMapper struct {
	device *Device
}

func CreateValveMapper(d *Device) DeviceMapper {
	return &valveMapper{d}
}

type HgDeviceType string

const (
	HgDeviceValve HgDeviceType = "action.devices.types.VALVE"
)

func (dm *valveMapper) Id() string {
	if dm == nil || dm.device == nil {
		return ""
	}
	return dm.device.Id
}

func (dm *valveMapper) ToHgDevice() (*HgDevice, error) {
	//NOTE: we only support SWS for now
	if dm.device != nil && strings.Index(strings.ToLower(dm.device.DeviceType), swsTypePrefix) == 0 {
		return dm.mapSws()
	}
	return nil, errors.New("input device type not supported: " + dm.device.DeviceType)
}

// SEE: https://answers.alarm.com/ADC/Partner/Partner_Tools_and_Services/Growth_and_Productivity_Services/Integrations/Alarm.com_Standard_API/OpenClose_Trait
func (dm *valveMapper) mapSws() (*HgDevice, error) {
	userSetPushOK := true //NOTE: we can turn off push this way for the user, leaving it on for now
	hd := HgDevice{
		Id:   dm.device.Id,
		Type: HgDeviceValve,
		Name: &HgDeviceName{
			Name: dm.device.Nickname,
			NickNames: []string{
				fmt.Sprintf("%v - %v", dm.device.Location.Nickname, dm.device.Nickname),
			},
			DefaultNames: []string{
				fmt.Sprintf("%v - %v", brand, swsName),
				fmt.Sprintf("%v %v", manufacturer, swsName),
				fmt.Sprintf("%v Smart Valve", manufacturer),
				"Flo Smart Valve",
				"Flo Device",
			},
		},
		Traits:      []HgDeviceTrait{TraitOpenClose},
		WillReport:  true,
		AgentConfig: &userSetPushOK,
		CustomData: &HgDevCustomDat{
			Mac:        dm.device.MacAddress,
			LocationId: dm.device.Location.Id,
		},
		Info: &HgDeviceInfo{
			Manufacturer: manufacturer,
			Model:        dm.device.DeviceModel,
			Mac:          dm.device.MacAddress,
			Serial:       dm.device.SerialNumber,
			SwVer:        dm.device.FirmwareVersion, //fw ver maps to swVer according to google docs
		},
	}
	e := hd.AttributesAppend( //combine multiple attributes from device traits
		&HgAttrOpenClose{Discrete: true},
	)
	return &hd, e
}

func (dm *valveMapper) ToHgStat(seq SeqGen) HgStat {
	var (
		dtBk = time.Now().UTC().Truncate(DUR_2_SEC).Add(-DUR_2_SEC) //date bucket of last X time
		evDt = DateTime(dtBk)                                       //minimal allowed age
		hg   = HgStatValve{
			Id:  dm.device.Id,
			Mac: dm.device.MacAddress,
		}
	)
	if seq != nil {
		hg.AdcSeqId = fmt.Sprint(seq.Next())
	}
	if dm.device.LastHeardFromTime != nil {
		evDt = dtMax(evDt, *dm.device.LastHeardFromTime)
	}
	hg.AdcEvtMs = dtToAdcMs(*dm.device.LastHeardFromTime)
	if hg.Online = Bool(dm.device.IsConnected); !hg.Online {
		hg.SetErrCode("deviceOffline", nil)
		hg.Status = "OFFLINE"
	}
	if dm.device.Valve != nil {
		switch valSt := strings.ToLower(dm.device.Valve.LastKnown); valSt {
		case "open":
			hg.OpenPct = 100
		case "stuck":
			if hg.Online {
				hg.SetErrCode("deviceJammingDetected", nil)
			}
		case "broken":
			if hg.Online {
				hg.SetErrCode("hardwareFailure", nil)
			}
		} //default: or "closed" -> 0
	}
	return &hg
}
