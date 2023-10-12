package main

import (
	"fmt"
)

type HgDeviceTrait string

const (
	/*
		TraitOnOff       HgDeviceTrait = "action.devices.traits.OnOff"
		TraitBrightness  HgDeviceTrait = "action.devices.traits.Brightness"
	*/
	TraitOpenClose   HgDeviceTrait = "action.devices.traits.OpenClose"
	TraitSensorState HgDeviceTrait = "action.devices.traits.SensorState"
	TraitEnergyStore HgDeviceTrait = "action.devices.traits.EnergyStorage"
)

type HgIntent string

const (
	IntentSync       HgIntent = "action.devices.SYNC"
	IntentQuery      HgIntent = "action.devices.QUERY"
	IntentExecute    HgIntent = "action.devices.EXECUTE"
	IntentDisconnect HgIntent = "action.devices.DISCONNECT"
)

type HgDevice struct {
	Id          string          `json:"id"`
	Type        HgDeviceType    `json:"type"`
	Name        *HgDeviceName   `json:"name"`
	Traits      []HgDeviceTrait `json:"traits"`
	WillReport  bool            `json:"willReportState"`
	AgentConfig *bool           `json:"notificationSupportedByAgent,omitempty"`
	Attributes  Attrs           `json:"attributes,omitempty"`
	CustomData  *HgDevCustomDat `json:"customData,omitempty"`
	Info        *HgDeviceInfo   `json:"deviceInfo"`
	AdcSeqId    string          `json:"alarmDotComSequenceId,omitempty"`
}

func (d *HgDevice) AttributesAppend(arr ...interface{}) error {
	var (
		es    = make([]error, 0)
		res   = &Attrs{}
		merge = func(a, b *Attrs) *Attrs {
			var (
				av = *a
				bv = *b
			)
			for k, v := range bv {
				av[k] = v
			}
			return &av
		}
	)
	for _, a := range arr {
		if att, e := CreateAttrs(a); e != nil {
			es = append(es, e)
		} else if att != nil {
			res = merge(res, att)
		}
	}
	if e := wrapErrors(es); e != nil {
		return e
	} else {
		d.Attributes = *res //replace w/ new attribute
		return nil
	}
}

type HgDeviceName struct {
	Name         string   `json:"name"`
	NickNames    []string `json:"nickNames,omitempty"`
	DefaultNames []string `json:"defaultNames,omitempty"`
}

type HgDeviceInfo struct {
	Manufacturer string `json:"manufacturer"`
	Model        string `json:"model"`
	HwVer        string `json:"hwVersion,omitempty"`
	SwVer        string `json:"swVersion,omitempty"`
	Serial       string `json:"serial,omitempty"`
	Mac          string `json:"macAddress"`
}

type HgDevCustomDat struct {
	Mac        string `json:"mac,omitempty" validate:"omitempty,hexadecimal,len=12"`
	LocationId string `json:"locationId,omitempty" validate:"omitempty,uuid4_rfc4122"`
	DeviceId   string `json:"device_id,omitempty" validate:"omitempty,uuid4_rfc4122"`
}

type OpenCloseDir string

const (
	HgOpenUP    OpenCloseDir = "UP"
	HgOpenDown  OpenCloseDir = "DOWN"
	HgOpenRight OpenCloseDir = "RIGHT"
	HgOpenLeft  OpenCloseDir = "LEFT"
	HgOpenIn    OpenCloseDir = "IN"
	HgOpenOut   OpenCloseDir = "OUT"
)

type HgAttrOpenClose struct {
	Discrete    bool           `json:"discreteOnlyOpenClose,omitempty"`
	Direction   []OpenCloseDir `json:"openDirection,omitempty"`
	CommandOnly bool           `json:"commandOnlyOpenClose,omitempty"`
	QueryOnly   bool           `json:"queryOnlyOpenClose,omitempty"`
}

type HgAttrEnergyStore struct {
	Rechargeable bool `json:"isRechargeable"`
}

type HgAttrSensorState struct {
	StatesSupported []*HgSensorSupported `json:"sensorStatesSupported"`
}

type HgSensorSupported struct {
	Name         string                `json:"name"`
	Capabilities *HgSensorCapabilities `json:"descriptiveCapabilities"`
}

type HgSensorCapabilities struct {
	States []string `json:"availableStates"`
}

/////////////
/* HG Errs */

func CreateHgError(code string, trace error) *HgError {
	debug := ""
	if trace != nil {
		debug = trace.Error()
	}
	return &HgError{"ERROR", code, trace, debug}
}

// HgError should fit Error interface
type HgError struct {
	Status    string `json:"status"`
	ErrorCode string `json:"errorCode,omitempty"`
	Trace     error  `json:"-"`                     //if wrapped, will not return to HG
	Debug     string `json:"debugString,omitempty"` //additional debug info returned to client API but not shown to end user
}

func (he *HgError) Inner() error {
	return he.Trace
}
func (he *HgError) Error() string {
	sb := _loggerSbPool.Get()
	defer _loggerSbPool.Put(sb)

	sb.WriteString(he.Status)
	if he.ErrorCode != "" {
		if sb.Len() > 0 {
			sb.WriteString(" - ")
		}
		sb.WriteString(he.ErrorCode)
	}
	if sb.Len() == 0 {
		return "ERROR - unknown"
	}
	return sb.String()
}
func (he HgError) String() string {
	return he.Error()
}

// HgIntentError should fit Error interface
type HgIntentError struct {
	RequestId string   `json:"requestId"`
	Payload   *HgError `json:"payload"`
	Trace     error    `json:"-"` //if wrapped, will not return to HG
}

func (he *HgIntentError) Inner() error {
	return he.Trace
}
func (he *HgIntentError) Error() string {
	return fmt.Sprintf("Intent[%v] %v", he.RequestId, he.Payload.Error())
}
func (he HgIntentError) String() string {
	return he.Error()
}

// HgDevicesError should fit Error interface
type HgDevicesError struct {
	RequestId string `json:"requestId"`
	Payload   struct {
		Devices map[string]*HgError `json:"devices"`
	} `json:"payload"`
	Trace error `json:"-"` //if wrapped, will not return to HG
}

func (he *HgDevicesError) Inner() error {
	return he.Trace
}
func (he *HgDevicesError) Error() string {
	sb := _loggerSbPool.Get()
	defer _loggerSbPool.Put(sb)

	sb.WriteString("Intent[")
	sb.WriteString(he.RequestId)
	sb.WriteString("]")
	if count := len(he.Payload.Devices); count > 0 {
		sb.WriteString(" ")
		for id, err := range he.Payload.Devices {
			sb.WriteString(id)
			sb.WriteString(":")
			sb.WriteString(err.Error())
			count--
			if count > 0 {
				sb.WriteString(", ")
			}
		}
	}
	return sb.String()
}
func (he HgDevicesError) String() string {
	return he.Error()
}

type HgStat interface {
	GetId() string
	SetErrCode(code string, e error)
	GetStatus() string
}

type HgStatErr struct {
	Id       string `json:"-"`
	Mac      string `json:"-"`
	AdcSeqId string `json:"alarmDotComSequenceId,omitempty"`

	Status     string `json:"status,omitempty"` //SUCCESS, OFFLINE, EXCEPTIONS, ERROR
	ErrorCode  string `json:"errorCode,omitempty"`
	ErrorDebug string `json:"debugString,omitempty"`
}

func (se *HgStatErr) GetId() string {
	if se == nil {
		return ""
	}
	return se.Id
}

func (se *HgStatErr) SetErrCode(code string, e error) {
	if se != nil && code != "" {
		if se.Status != "OFFLINE" {
			se.Status = "ERROR"
		}
		se.ErrorCode = code
		if e != nil {
			se.ErrorDebug = e.Error()
		}
	}
}

func (se *HgStatErr) GetStatus() string {
	if se == nil {
		return ""
	}
	return se.Status
}

func (se HgStatErr) String() string {
	return fmt.Sprintf("did=%v mac=%v %v", se.Id, se.Mac, tryToJson(se))
}

func (se *HgStatErr) Error() string {
	if se == nil {
		return ""
	}
	s := fmt.Sprintf("%v: %v", se.ErrorCode, se.Status)
	if s[0] == ':' {
		s = s[2:]
	}
	return s
}

type HgStatValve struct {
	Id       string `json:"-"`
	Mac      string `json:"-"`
	Online   bool   `json:"online"`
	OpenPct  int32  `json:"openPercent"`
	AdcSeqId string `json:"alarmDotComSequenceId,omitempty"`
	AdcEvtMs string `json:"alarmDotComEventTimestampMs,omitempty"`

	Status     string `json:"status,omitempty"` //SUCCESS, OFFLINE, EXCEPTIONS, ERROR
	ErrorCode  string `json:"errorCode,omitempty"`
	ErrorDebug string `json:"debugString,omitempty"`
}

func (ss *HgStatValve) GetId() string {
	if ss == nil {
		return ""
	}
	return ss.Id
}

func (ss *HgStatValve) SetErrCode(code string, e error) {
	if ss != nil && code != "" {
		if ss.Status != "OFFLINE" {
			ss.Status = "ERROR"
		}
		ss.ErrorCode = code
		if e != nil {
			ss.ErrorDebug = e.Error()
		}
	}
}

func (ss *HgStatValve) GetStatus() string {
	if ss == nil {
		return ""
	}
	return ss.Status
}

func (ss HgStatValve) String() string {
	return fmt.Sprintf("did=%v mac=%v %v", ss.Id, ss.Mac, tryToJson(ss))
}

const (
	HgSensorLeak        = "WaterLeak"
	HgSensorLeakUnknown = "unknown"
	HgSensorLeakNo      = "no leak"
	HgSensorLeakYes     = "leak"

	HgSensorShutoff    = "AutomaticShutOff"
	HgSensorShutoffNo  = "no shut off"
	HgSensorShutoffYes = "shut off"
)

type HgSensorState struct {
	Name         string `json:"name"`
	CurrentState string `json:"currentSensorState"`
}

const (
	EnergyLevelEmpty  = "CRITICALLY_LOW"
	EnergyLevelLow    = "LOW"
	EnergyLevelMedium = "MEDIUM"
	EnergyLevelHigh   = "HIGH"
	EnergyLevelFull   = "FULL"
)

type HgStatsLeakSensor struct {
	Id       string `json:"-"`
	Mac      string `json:"-"`
	Online   bool   `json:"online"`
	AdcSeqId string `json:"alarmDotComSequenceId,omitempty"`
	AdcEvtMs string `json:"alarmDotComEventTimestampMs,omitempty"`

	States []*HgSensorState `json:"currentSensorStateData"`

	Level    string         `json:"descriptiveCapacityRemaining,omitempty"`
	Capacity []*HgValueUnit `json:"capacityRemaining,omitempty"`
	Charging *bool          `json:"isCharging,omitempty"`
	Plugged  *bool          `json:"isPluggedIn,omitempty"`

	Status     string `json:"status,omitempty"` //SUCCESS, OFFLINE, EXCEPTIONS, ERROR
	ErrorCode  string `json:"errorCode,omitempty"`
	ErrorDebug string `json:"debugString,omitempty"`
}

type HgValueUnit struct {
	Value int32  `json:"rawValue"`
	Unit  string `json:"unit"` //PERCENTAGE
}

func (ws *HgStatsLeakSensor) GetId() string {
	if ws == nil {
		return ""
	}
	return ws.Id
}

func (ws *HgStatsLeakSensor) SetErrCode(code string, e error) {
	if ws != nil && code != "" {
		if ws.Status != "OFFLINE" {
			ws.Status = "ERROR"
		}
		ws.ErrorCode = code
		if e != nil {
			ws.ErrorDebug = e.Error()
		}
	}
}

func (ws *HgStatsLeakSensor) GetStatus() string {
	if ws == nil {
		return ""
	}
	return ws.Status
}

func (ws *HgStatsLeakSensor) String() string {
	return fmt.Sprintf("did=%v mac=%v %v", ws.Id, ws.Mac, tryToJson(ws))
}
