package main

import (
	"fmt"
	"regexp"
	"time"

	"github.com/labstack/gommon/log"
)

type GetDevicesBody struct {
	DeviceIds []string `json:"deviceIds"`
}

type DefaultFirmwareProperty struct {
	Key          string                        `json:"key"`
	Value        interface{}                   `json:"value"`
	Provisioning *FirmwarePropertyProvisioning `json:"provisioning,omitempty"`
}

type FirmwarePropertyProvisioning struct {
	OnPairing *FirmwarePropertyProvisioningRules `json:"onPairing,omitempty"`
}

type FirmwarePropertyProvisioningRules struct {
	MacAddress string `json:"macAddress"`
	Enabled    bool   `json:"enabled"`
}

func (r FirmwarePropertyProvisioningRules) Validate(macAddress string) (bool, error) {
	if !r.Enabled {
		return false, nil
	}
	if r.MacAddress != "" {
		re, err := regexp.Compile(r.MacAddress)
		if err != nil {
			return false, err
		}
		return re.MatchString(macAddress), nil
	}
	return true, nil
}

type ThresholdDefinition struct {
	OkMin    *float64 `json:"okMin,omitempty"`
	OkMax    *float64 `json:"okMax,omitempty"`
	MinValue *float64 `json:"minValue,omitempty"`
	MaxValue *float64 `json:"maxValue,omitempty"`
}

type HardwareThresholds struct {
	Gpm             *ThresholdDefinition `json:"gpm,omitempty"`
	Psi             *ThresholdDefinition `json:"psi,omitempty"`
	Lpm             *ThresholdDefinition `json:"lpm,omitempty"`
	Kpa             *ThresholdDefinition `json:"kPa,omitempty"`
	TempF           *ThresholdDefinition `json:"tempF,omitempty"`
	TempC           *ThresholdDefinition `json:"tempC,omitempty"`
	Humidity        *ThresholdDefinition `json:"humidity,omitempty"`
	Battery         *ThresholdDefinition `json:"battery,omitempty"`
	TempEnabled     *bool                `json:"tempEnabled,omitempty"`
	HumidityEnabled *bool                `json:"humidityEnabled,omitempty"`
	BatteryEnabled  *bool                `json:"batteryEnabled,omitempty"`
}

type Audio struct {
	SnoozeTo      *time.Time `json:"snoozeTo,omitempty"`
	SnoozeSeconds *int64     `json:"snoozeSeconds,omitempty"`
}

type FirmwareInfo struct {
	Version        *string `json:"version,omitempty"`
	SourceType     *string `json:"sourceType,omitempty"`
	SourceLocation *string `json:"sourceLocation,omitempty"`
}

type ValveStateSource struct {
	Id   string `json:"id"`
	Type string `json:"type"`
	Name string `json:"name,omitempty"`
}

type ValveStateCause struct {
	Type   string            `json:"type"`
	Source *ValveStateSource `json:"source,omitempty"`
}

type ValveStateMeta struct {
	IsEmpty bool             `json:"-"`
	Target  string           `json:"target,omitempty"`
	Cause   *ValveStateCause `json:"cause,omitempty"`
}

// DeviceInternal is the internal device struct (used for scanning data into from DB)
type DeviceInternal struct {
	DeviceId           *string             `json:"device_id,omitempty"`
	IsConnected        *bool               `json:"is_connected,omitempty"`
	IsMobile           *bool               `json:"mobile_pair,omitempty"`
	SystemMode         *string             `json:"system_mode,omitempty"`
	ValveState         *string             `json:"valve_state,omitempty"`
	FwVersion          *string             `json:"firmware_version,omitempty"`
	Created            *time.Time          `json:"created_time,omitempty"`
	LastHeardFrom      *time.Time          `json:"last_heard_from_time,omitempty"`
	Updated            *time.Time          `json:"updated_time,omitempty"`
	FwPropertiesRaw    *FwPropertiesRaw    `json:"fw_properties_raw,omitempty"`
	FwUpdateReq        *FwUpdateReq        `json:"fw_properties_req,omitempty"`
	Make               *string             `json:"make,omitempty"`
	Model              *string             `json:"model,omitempty"`
	HardwareThresholds *HardwareThresholds `json:"hw_thresholds,omitempty"`
	MuteAudioUntil     *time.Time          `json:"mute_audio_until,omitempty"`
	LatestFwInfo       *FirmwareInfo       `json:"latest_fw_info,omitempty"`
	ComponentHealth    *ComponentHealth    `json:"componentHealth,omitempty"`
	ValveStateMeta     *ValveStateMeta     `json:"valve_state_meta,omitempty"`
}

// FwPropertiesRaw is the internal device properties struct (used to bind kafka payload)
type FwPropertiesRaw struct {
	Id         *string                 `json:"id,omitempty"`
	RequestId  *string                 `json:"request_id,omitempty"`
	DeviceId   *string                 `json:"device_id,omitempty"`
	Timestamp  *int64                  `json:"timestamp,omitempty"`
	Reason     *string                 `json:"reason,omitempty"`
	Properties *map[string]interface{} `json:"properties,omitempty"`
}

// DeviceBase is the base device properties struct
type DeviceBase struct {
	DeviceId           *string                 `json:"deviceId" minimum:"12" maximum:"12" example:"000005f0cccc,omitempty"`
	IsConnected        *bool                   `json:"isConnected" example:"true,omitempty"`
	IsMobile           *bool                   `json:"mobilePair,omitempty"`
	FwVersion          *string                 `json:"fwVersion" example:"3.5.12,omitempty"`
	Created            *time.Time              `json:"createdTime" example:"2019-05-03T22:30:15.82285Z,omitempty"`
	LastHeardFrom      *time.Time              `json:"lastHeardFromTime" example:"2019-05-06T07:14:36Z,omitempty"`
	Updated            *time.Time              `json:"updatedTime" example:"2019-05-06T07:14:36Z,omitempty"`
	FwProperties       *map[string]interface{} `json:"fwProperties,omitempty"`
	FwUpdateReq        *FwUpdateReq            `json:"fwPropertiesUpdateReq,omitempty"`
	Make               *string                 `json:"make,omitempty"`
	Model              *string                 `json:"model,omitempty"`
	HardwareThresholds *HardwareThresholds     `json:"hwThresholds,omitempty"`
	Audio              *Audio                  `json:"audio,omitempty"`
	LatestFwInfo       *FirmwareInfo           `json:"latestFwInfo,omitempty"`
	ComponentHealth    *ComponentHealth        `json:"componentHealth,omitempty"`
	ValveStateMeta     *ValveStateMeta         `json:"valveStateMeta,omitempty"`
}

type ComponentHealth struct {
	Valve *ComponentInfo `json:"valve,omitempty"`
	Temp  *ComponentInfo `json:"temp,omitempty"`
	PSI   *ComponentInfo `json:"psi,omitempty"`
	Water *ComponentInfo `json:"water,omitempty"`
	RH    *ComponentInfo `json:"rh,omitempty"`
}

type ComponentInfo struct {
	Health  string    `json:"health"`
	Updated time.Time `json:"updated,omitempty"`
}

// Meta is the meta data requests pagination
type Meta struct {
	Total  int `json:"total" example:"1"`
	Offset int `json:"offset" example:"0"`
	Limit  int `json:"limit" example:"10"`
}

// Devices is the struct to be used for multiple devices response
type Devices struct {
	Meta  Meta         `json:"meta"`
	Items []DeviceBase `json:"items"`
}

// FwPropertiesSetter is the firmware properties setter
type FwPropertiesSetter struct {
	Id           string                 `json:"id"`
	RequestId    string                 `json:"request_id"`
	FwProperties map[string]interface{} `json:"properties"`
}

// DeviceRealTime is the device real time data from stored in the Firestore
type DeviceRealTime struct {
	DeviceId     string                 `json:"-"`
	Telemetry    map[string]interface{} `json:"telemetry"`
	Connectivity map[string]interface{} `json:"connectivity"`
	ValveState   map[string]interface{} `json:"valve"`
	SystemMode   map[string]interface{} `json:"systemMode"`
}

type DevicesLatestTelemetry struct {
	Devices []LatestTelemetry `json:"devices"`
}

type LatestTelemetry struct {
	DeviceId   string  `json:"macAddress"`
	Psi        float64 `json:"psi"`
	TempF      int     `json:"tempF"`
	ValveState int     `json:"valveState"`
	SystemMode int     `json:"systemMode"`
}

// DeviceExtended is the extended device properties struct
type DeviceExtended struct {
	DeviceBase
	DeviceRealTime
}

// MacAddressRegex is the device id regex
var MacAddressRegex *regexp.Regexp
var UuidRegex *regexp.Regexp

// CompileDeviceServiceRegexes compiles device service regexes
func CompileDeviceServiceRegexes() {
	var err error
	MacAddressRegex, err = regexp.Compile("^([a-fA-F0-9]{12})$")
	if err != nil {
		log.Errorf("failed to compile mac address regex, err: %v", err)
	}

	UuidRegex, err = regexp.Compile("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[8|9|aA|bB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}$")
	if err != nil {
		log.Errorf("failed to compile uuid regex, err: %v", err)
	}
}

func isValidDeviceMac(macAddress string) bool {
	return MacAddressRegex.MatchString(macAddress)
}

func isValidUuid(deviceId string) bool {
	return UuidRegex.MatchString(deviceId)
}

func isDevicePuck(device DeviceBase) bool {
	return device.Make != nil && *(device.Make) == "puck_oem"
}

type TailDeviceReq struct {
	DeviceId string `json:"deviceId" query:"deviceId"` //start with this id and get the next Nth (limit) DeviceSummary
	Limit    int    `json:"limit" query:"limit"`       //how many DeviceSummary to be returned in a batch, max 500
}

func (t *TailDeviceReq) Normalize() *TailDeviceReq {
	if t.Limit < 1 {
		t.Limit = 100
	} else if t.Limit > 500 {
		t.Limit = 500
	}
	return t
}

// return batch of DeviceSummary for this request, if the end is reached, lastRowFetched will be set to true
type TailDeviceResp struct {
	Params         TailDeviceReq    `json:"params"`         //what was requested & cleaned by API
	LastRowFetched bool             `json:"lastRowFetched"` //true if we've reach the end, effectively an EOF signal
	Devices        []*DeviceSummary `json:"devices"`        //what was found for the batch of data.  Client can also check for empty as a fail-safe for the above EOF
}

type DeviceSummary struct {
	DeviceId    string `json:"deviceId" minimum:"12" maximum:"12" example:"000005f0cccc,omitempty"`
	IsConnected bool   `json:"isConnected" example:"true,omitempty"`
	IsInstalled bool   `json:"isInstalled" example:"true,omitempty"`
	Make        string `json:"make,omitempty"`
	Model       string `json:"model,omitempty"`
}

type FwUpdateReq struct {
	DeviceId string                 `json:"-"`
	Meta     FwMeta                 `json:"meta,omitempty"`
	FwProps  map[string]interface{} `json:"fwProperties,omitempty"`
}

type FwMeta map[string]interface{}

func (m *FwMeta) get(name string) (interface{}, bool) {
	if m != nil {
		var mv map[string]interface{} = *m
		v, ok := mv[name]
		return v, ok
	}
	return nil, false
}

func (m *FwMeta) stringPropRoot(name string) string {
	if id, ok := m.get(name); ok {
		return fmt.Sprint(id) //safest cast
	}
	return ""
}

func (m *FwMeta) UserId() string {
	return m.stringPropRoot("userId")
}

func (m *FwMeta) AccountId() string {
	return m.stringPropRoot("accountId")
}

func (m *FwMeta) LocationId() string {
	return m.stringPropRoot("locationId")
}
