package main

import (
	"encoding/json"
	"time"
)

type EntityActivityMessage struct {
	Id        string               `json:"id"`
	Date      string               `json:"date"`
	Type      string               `json:"type"`
	Action    string               `json:"action"`
	RequestID string               `json:"requestId"`
	Item      EntityActivityDevice `json:"item"`
}

type EntityActivityMessageRawItem struct {
	Id        string          `json:"id"`
	Date      string          `json:"date"`
	Type      string          `json:"type"`
	Action    string          `json:"action"`
	RequestID string          `json:"requestId"`
	Item      json.RawMessage `json:"item,omitempty"`
}

/*
 * NOTE: Uses custom marshaller to deal with optional booleans
 */
type EntityActivityDevice struct {
	MacAddress        string                 `json:"macAddress"`
	Id                string                 `json:"id"`
	DeviceModel       string                 `json:"deviceModel,omitempty"`
	DeviceType        string                 `json:"deviceType,omitempty"`
	Nickname          string                 `json:"nickname,omitempty"`
	SerialNumber      string                 `json:"serialNumber,omitempty"`
	FwVersion         string                 `json:"fwVersion,omitempty"`
	LastHeardFromTime string                 `json:"lastHeardFromTime,omitempty"`
	Location          EntityActivityLocation `json:"location,omitempty"`
	LTEPaired         OptionalBool           `json:"lte_paired,omitempty"`
}

type EntityActivityLocation struct {
	Id      string                `json:"id"`
	Account EntityActivityAccount `json:"account,omitempty"`
}

type EntityActivityAccount struct {
	Id   string `json:"id,omitempty"`
	Type string `json:"type,omitempty"`
}

type Device struct {
	Id           string       `json:"id"`
	MacAddress   string       `json:"macAddress"`
	IsConnected  bool         `json:"isConnected"`
	FwVersion    string       `json:"fwVersion"`
	DeviceModel  string       `json:"deviceModel"`
	DeviceType   string       `json:"deviceType"`
	Location     Location     `json:"location"`
	SystemMode   SystemMode   `json:"systemMode"`
	Connectivity Connectivity `json:"connectivity"`
}

type Connectivity struct {
	Ssid string           `json:"ssid,omitempty"`
	LTE  *LTEConnectivity `json:"lte,omitempty"`
}

type LTEConnectivity struct {
	IMEI  string `json:"imei"`
	ICCID string `json:"iccid"`
}

type Account struct {
	Id    string       `json:"id"`
	Type  string       `json:"type"`
	Owner *UserSummary `json:"owner"`
}

type UserSummary struct {
	Id          string `json:"id,omitempty"`
	Email       string `json:"email,omitempty"`
	FirstName   string `json:"firstName,omitempty"`
	LastName    string `json:"lastName,omitempty"`
	PhoneMobile string `json:"phoneMobile,omitempty"`
	Locale      string `json:"locale,omitempty"`
}

type Location struct {
	Id         string     `json:"id"`
	Address    string     `json:"address,omitempty"`
	City       string     `json:"city,omitempty"`
	Country    string     `json:"country,omitempty"`
	State      string     `json:"state,omitempty"`
	Timezone   string     `json:"timezone"`
	SystemMode SystemMode `json:"systemMode"`
	Devices    []Device   `json:"devices"`
	Account    *Account   `json:"account,omitempty"`
}

type SystemModeValue = string

const (
	SM_Home  SystemModeValue = "home"
	SM_Away  SystemModeValue = "away"
	SM_Sleep SystemModeValue = "sleep"
)

type SystemMode struct {
	IsLocked      bool            `json:"isLocked"`
	ShouldInherit bool            `json:"shouldInherit"`
	LastKnown     SystemModeValue `json:"lastKnown"`
	Target        SystemModeValue `json:"target"`
	RevertMode    SystemModeValue `json:"revertMode"`
	RevertMinutes int             `json:"revertMinutes"`
}

type TaskStatus int

const (
	TS_Pending    TaskStatus = 1
	TS_InProgress TaskStatus = 2
	TS_Completed  TaskStatus = 4
	TS_Canceled   TaskStatus = 10
	TS_Failed     TaskStatus = 99
)

type MudTaskType string

const (
	Type_DefaultSettings MudTaskType = "set_default_settings"
	Type_FWProperties    MudTaskType = "set_fw_properties"
)

type Task struct {
	Id         string
	MacAddress string
	Type       MudTaskType
	Status     TaskStatus
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type TaskFilter struct {
	Type       MudTaskType
	Status     []TaskStatus
	MacAddress string
}

type ValveThresholdValues struct {
	Duration float32 `json:"duration"`
	Volume   float32 `json:"volume"`
	FlowRate float32 `json:"flowRate"`
}

type PuckThresholdValues struct {
	MinBattery *float32 `json:"minBattery,omitempty"`
	MaxBattery *float32 `json:"maxBattery,omitempty"`

	MinTempF *float32 `json:"minTempF,omitempty"`
	MaxTempF *float32 `json:"maxTempF,omitempty"`

	MinHumidity *float32 `json:"minHumidity,omitempty"`
	MaxHumidity *float32 `json:"maxHumidity,omitempty"`
}

type Repeat struct {
	Daily DaysOfWeek `json:"daily"`
}

type DaysOfWeek struct {
	Monday    bool `json:"monday"`
	Tuesday   bool `json:"tuesday"`
	Wednesday bool `json:"wednesday"`
	Thursday  bool `json:"thursday"`
	Friday    bool `json:"friday"`
	Saturday  bool `json:"saturday"`
	Sunday    bool `json:"sunday"`
}

type ThresholdDefaults struct {
	AccountId     *string
	DefaultValues *string
	StartMinute   int
	EndMinute     int
	Order         int
	Repeat        Repeat
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

const (
	DT_Puck  string = "puck_oem"
	DT_Valve string = "flo_device_v2"
)

const (
	AT_Enterprise string = "enterprise"
	AT_Personal   string = "personal"
)

type UpdateFloSensePayload struct {
	MacAddress string    `json:"macAddress"`
	FloSense   *FloSense `json:"floSense"`
}

type FloSenseDevice struct {
	MacAddress string           `json:"macAddress"`
	FloSense   *FloSense        `json:"floSense"`
	Pes        PesScheduleItems `json:"pes"`
}

type PesScheduleItems struct {
	Schedule Schedule `json:"schedule"`
}

type Schedule struct {
	SyncRequired bool      `json:"syncRequired"`
	LastSync     time.Time `json:"lastSync"`
}

type FloSense struct {
	ShutoffLevel *int              `json:"shutoffLevel"`
	UserEnabled  *bool             `json:"userEnabled"`
	PesOverride  *FloSenseOverride `json:"pesOverride"`
}

type FloSenseOverride struct {
	Home *PesScheduleItem `json:"home"`
	Away *PesScheduleItem `json:"away"`
}

type PesScheduleItem struct {
	Id              string         `json:"id"` // uuid
	Name            string         `json:"name"`
	Mode            string         `json:"mode"`
	StartTime       string         `json:"startTime"`
	EndTime         string         `json:"endTime"`
	Repeat          Repeat         `json:"repeat"`
	EventLimits     PesEventLimits `json:"eventLimits"`
	ShutoffDisabled *bool          `json:"shutoffDisabled"`
	ShutoffDelay    *int           `json:"shutoffDelay"` // secs
	Order           int            `json:"order"`
	Created         time.Time      `json:"created"`
	ICalString      string         `json:"iCalString"`
	DeviceConfirmed bool           `json:"deviceConfirmed"`
}

type PesEventLimits struct {
	Duration         float32 `json:"duration"`         // max_duration
	Volume           float32 `json:"volume"`           // max_volume
	FlowRate         float32 `json:"flowRate"`         // max_rate
	FlowRateDuration float32 `json:"flowRateDuration"` // max_rate_duration
}

type SystemModePayload struct {
	IsLocked      *bool            `json:"isLocked"`
	ShouldInherit *bool            `json:"shouldInherit"`
	LastKnown     *SystemModeValue `json:"lastKnown"`
	Target        *SystemModeValue `json:"target"`
	RevertMode    *SystemModeValue `json:"revertMode"`
	RevertMinutes *int             `json:"revertMinutes"`
}

type EventWrapper struct {
	Header   *EventRequestHeader `json:"header" validate:"required"`
	Request  *EventRequestBody   `json:"request" validate:"required"`
	Response *EventResponseBody  `json:"response,omitempty"`
}
type EventRequestHeader struct {
	RequestID string `json:"id" validate:"required"`
	Timestamp string `json:"timestamp" validate:"required"`
	Source    string `json:"source" validate:"required"`
}

type EventRequestBody struct {
	Entity  string           `json:"entity" validate:"required"`
	Action  string           `json:"action" validate:"required"`
	Payload *json.RawMessage `json:"payload" validate:"required"`
}

type EventResponseBody struct {
	Timestamp string           `json:"timestamp" validate:"required"`
	Code      int64            `json:"code" validate:"required"`
	Payload   *json.RawMessage `json:"payload" validate:"required"`
	Message   string           `json:"message,omitempty"`
}
