package main

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type sensorMapper struct {
	device    *Device
	incidents []*Incident
}

const (
	HgDeviceSensor HgDeviceType = "action.devices.types.SENSOR"
)

func CreateSensorMapper(device *Device, incidents []*Incident) DeviceMapper {
	return &sensorMapper{device, incidents}
}

func (dm *sensorMapper) isSws() bool {
	return strings.Index(strings.ToLower(dm.device.DeviceType), swsTypePrefix) == 0
}

func (dm *sensorMapper) isSwd() bool {
	return strings.Index(strings.ToLower(dm.device.DeviceType), swdTypePrefix) == 0
}

func (dm *sensorMapper) ToHgDevice() (*HgDevice, error) {
	if dm.device != nil {
		if dm.isSws() {
			return dm.mapSws() // We are mapping our SWS as a leak sensor on ADC cloud because it has that capability
		} else if dm.isSwd() {
			return dm.mapSwd()
		}
	}
	return nil, errors.New("input device type not supported: " + dm.device.DeviceType)
}

func (dm *sensorMapper) mapCommon() *HgDevice {
	userSetPushOK := true //NOTE: we can turn off push this way for the user, leaving it on for now
	hd := HgDevice{
		Id:          dm.safeId(),
		Type:        HgDeviceSensor,
		Traits:      []HgDeviceTrait{TraitSensorState},
		WillReport:  true,
		AgentConfig: &userSetPushOK,
		CustomData: &HgDevCustomDat{
			Mac:        dm.device.MacAddress,
			LocationId: dm.device.Location.Id,
			DeviceId:   dm.device.Id,
		},
		Info: &HgDeviceInfo{
			Manufacturer: manufacturer,
			Model:        dm.device.DeviceModel,
			Mac:          dm.device.MacAddress,
			Serial:       dm.device.SerialNumber,
			SwVer:        dm.device.FirmwareVersion, //fw ver maps to swVer according to google docs
		},
	}
	return &hd
}

func (dm *sensorMapper) Id() string {
	return dm.safeId()
}

// adc device id is universally unique, if we don't do this, it will err
func (dm *sensorMapper) safeId() string {
	if dm == nil || dm.device == nil {
		return ""
	}
	if dm.isSws() {
		return fmt.Sprintf("%v:sensor", dm.device.Id)
	}
	return dm.device.Id //return real id, don't proxy if it's not sws
}

func (dm *sensorMapper) mapSwd() (*HgDevice, error) {
	hd := dm.mapCommon()
	hd.Traits = append(hd.Traits, TraitEnergyStore) //add battery meter for swd
	hd.Name = &HgDeviceName{
		Name: dm.device.Nickname,
		NickNames: []string{
			fmt.Sprintf("%v - %v", dm.device.Location.Nickname, dm.device.Nickname),
		},
		DefaultNames: []string{
			fmt.Sprintf("%v - %v", brand, swdName),
			fmt.Sprintf("%v %v", manufacturer, swdName),
			fmt.Sprintf("%v Smart Leak Detector", manufacturer),
			fmt.Sprintf("%v Leak Sensor", manufacturer),
			"Flo Leak Sensor",
			"Flo Leak Detector",
		},
	}
	e := hd.AttributesAppend( //combine multiple attributes from device traits
		dm.sensorAttr(),
	)
	return hd, e
}

// SEE: https://answers.alarm.com/Partner/Partner_Tools_and_Services/Growth_and_Productivity_Services/Integrations/Alarm.com_Standard_API/SensorState_Trait
func (dm *sensorMapper) mapSws() (*HgDevice, error) {
	hd := dm.mapCommon()
	hd.Name = &HgDeviceName{
		Name: dm.device.Nickname,
		NickNames: []string{
			fmt.Sprintf("%v - %v Sensor", dm.device.Location.Nickname, dm.device.Nickname),
		},
		DefaultNames: []string{
			fmt.Sprintf("%v - %v Sensor", brand, swsName),
			fmt.Sprintf("%v %v Sensor", manufacturer, swsName),
			fmt.Sprintf("%v Smart Valve Sensor", manufacturer),
			"Flo Smart Valve Sensor",
			"Flo Device Sensor",
		},
	}
	e := hd.AttributesAppend( //combine multiple attributes from device traits
		dm.sensorAttr(),
		HgAttrEnergyStore{Rechargeable: false},
	)
	return hd, e
}

func (dm *sensorMapper) sensorAttr() *HgAttrSensorState {
	var (
		leak = HgSensorSupported{
			Name: HgSensorLeak,
			Capabilities: &HgSensorCapabilities{
				States: []string{HgSensorLeakUnknown, HgSensorLeakNo, HgSensorLeakYes},
			},
		}
		shutoff = HgSensorSupported{
			Name: HgSensorShutoff,
			Capabilities: &HgSensorCapabilities{
				States: []string{HgSensorShutoffNo, HgSensorShutoffYes},
			},
		}
	)
	return &HgAttrSensorState{
		StatesSupported: []*HgSensorSupported{&leak, &shutoff},
	}
}

const DUR_2_SEC = time.Duration(2) * time.Second

func (dm *sensorMapper) ToHgStat(seq SeqGen) HgStat {
	var (
		dtBk = time.Now().UTC().Truncate(DUR_2_SEC).Add(-DUR_2_SEC) //date bucket of last X time
		evDt = DateTime(dtBk)                                       //min oldest time
		ss   = HgStatsLeakSensor{
			Id:  dm.safeId(),
			Mac: dm.device.MacAddress,
		}
	)
	if dm.device.LastHeardFromTime != nil {
		evDt = dtMax(evDt, *dm.device.LastHeardFromTime)
	}
	if seq != nil {
		ss.AdcSeqId = fmt.Sprint(seq.Next())
	}
	if ss.Online = Bool(dm.device.IsConnected); !ss.Online {
		ss.SetErrCode("deviceOffline", nil)
		ss.Status = "OFFLINE"
	}
	if dm.isSwd() {
		dm.appendBatteryInfo(&ss)
	}
	if dm.incidents == nil {
		ss.States = []*HgSensorState{
			{Name: HgSensorLeak, CurrentState: HgSensorLeakUnknown},
		}
	} else {
		var (
			leak  = dm.leakDetected()
			shut  = dm.shutoffDetected()
			isNil = func(alr *Incident) bool {
				if alr == nil {
					return true
				} else {
					return false
				}
			}
			noLeak = isNil(leak)
			noShut = isNil(shut)
			leakSt = ifStr(noShut && noLeak, HgSensorLeakNo, HgSensorLeakYes) // not possible to shutoff w/o a "leak"
			shutSt = ifStr(noShut, HgSensorShutoffNo, HgSensorShutoffYes)
		)
		if shut != nil {
			evDt = dtMax(shut.Created, evDt)
		}
		if leak != nil {
			evDt = dtMax(leak.Created, evDt)
		}
		ss.States = []*HgSensorState{
			{Name: HgSensorLeak, CurrentState: leakSt},
			{Name: HgSensorShutoff, CurrentState: shutSt},
		}
	}
	ss.AdcEvtMs = dtToAdcMs(evDt)
	return &ss
}

func dtMax(a, b DateTime) DateTime {
	if a.UTC().Unix() >= b.UTC().Unix() {
		return a
	} else {
		return b
	}
}

func (dm *sensorMapper) appendBatteryInfo(ss *HgStatsLeakSensor) *HgStatsLeakSensor {
	ss.Capacity = []*HgValueUnit{
		{dm.device.Battery.Level, "PERCENTAGE"},
	}
	if lv := dm.device.Battery.Level; lv <= 3 {
		ss.Level = EnergyLevelEmpty
	} else if lv <= 10 {
		ss.Level = EnergyLevelLow
	} else if lv <= 60 {
		ss.Level = EnergyLevelMedium
	} else if lv <= 90 {
		ss.Level = EnergyLevelHigh
	} else {
		ss.Level = EnergyLevelFull
	}
	return ss
}

func dtToAdcMs(dt DateTime) string {
	if d := dt.UTC(); d.Year() > 2020 {
		return fmt.Sprint(d.UnixNano() / 1000000)
	}
	return ""
}
func ifStr(ok bool, x, y string) string {
	if ok {
		return x
	} else {
		return y
	}
}

var (
	swsLeakAlarmIds = map[int32]string{
		10: "Water gpm above threshold",
		11: "Water gallons above threshold",
		26: "Duration for single flow event exceeds PES settings",

		70: "FS: High flow rate overall",
		71: "FS: High event duration overall",
		72: "FS: Unusual activity at this time of day",
		73: "FS: The combination of water event parameters is unusual for this device",
		74: "FS: High volume event overall. Also known as Unusual Volume",
	}
	swsShutoffAlarmIds = map[int32]string{
		51: "Water shutoff due to high flow rate",
		52: "Water shutoff due to maximum usage per event",
		53: "Water shutoff due to maximum duration per event",
		55: "Water shutoff due to high flow rate in away mode",

		80: "FS: Water System Shutoff - Alarm 70",
		81: "FS: Water System Shutoff - Alarm 71",
		82: "FS: Water System Shutoff - Alarm 72",
		83: "FS: Water System Shutoff - Alarm 73",
		84: "FS: Water System Shutoff - Alarm 74",
	}

	swdLeakAlarmIds = map[int32]string{
		100: "Water Detected",
	}
	swdShutoffAlarmIds = map[int32]string{
		101: "Water Shutoff By Detector",
	}
)

func (dm *sensorMapper) alarmIdDef(sensorType string) map[int32]string {
	if dm != nil {
		switch sensorType {
		case HgSensorLeak:
			if dm.isSws() {
				return swsLeakAlarmIds
			} else if dm.isSwd() {
				return swdLeakAlarmIds
			}
		case HgSensorShutoff:
			if dm.isSws() {
				return swsShutoffAlarmIds
			} else if dm.isSwd() {
				return swdShutoffAlarmIds
			}
		}
	}
	return nil
}

func (dm *sensorMapper) leakDetected() (detected *Incident) {
	def := dm.alarmIdDef(HgSensorLeak)
	for _, o := range dm.incidents {
		if !strings.EqualFold(o.Alarm.Severity, "critical") {
			continue //ignore all none critical alarms
		}
		if alarmNote, found := def[o.Alarm.Id]; found {
			detected = o
			_log.Info("sensorMapper.leakDetected: FOUND | did=%v mac=%v type=%v | alarm=%v %v - %v",
				dm.device.Id, dm.device.MacAddress, dm.device.DeviceType, o.Alarm.Id, o.Title, alarmNote)
			break
		}
	}
	if detected == nil {
		_log.Debug("sensorMapper.leakDetected: NONE | did=%v mac=%v type=%v",
			dm.device.Id, dm.device.MacAddress, dm.device.DeviceType)
	}
	return
}

func (dm *sensorMapper) shutoffDetected() (detected *Incident) {
	def := dm.alarmIdDef(HgSensorShutoff)
	for _, o := range dm.incidents {
		if !strings.EqualFold(o.Alarm.Severity, "critical") {
			continue //ignore all none critical alarms
		}
		if alarmNote, found := def[o.Alarm.Id]; found {
			detected = o
			_log.Info("sensorMapper.shutoffDetected: FOUND | did=%v mac=%v type=%v | alarm=%v %v - %v",
				dm.device.Id, dm.device.MacAddress, dm.device.DeviceType, o.Alarm.Id, o.Title, alarmNote)
			break
		}
	}
	if detected == nil {
		_log.Debug("sensorMapper.shutoffDetected: NONE | did=%v mac=%v type=%v",
			dm.device.Id, dm.device.MacAddress, dm.device.DeviceType)
	}
	return
}
