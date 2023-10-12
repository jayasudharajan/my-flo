package main

type DevicesApi struct {
	Meta  DevicesMetaApi `json:"meta"`
	Items []DeviceApi    `json:"items"`
}

type DevicesMetaApi struct {
	Total  int `json:"total"`
	Offset int `json:"offset"`
}

type DeviceApi struct {
	Id          string `json:"id"`
	MacAddress  string `json:"deviceId"`
	IsConnected bool   `json:"isConnected"`
	FwVersion   string `json:"fwVersion"`
	DeviceModel string `json:"model"`
	DeviceType  string `json:"make"`
}

// DeviceApiPayload is the request to upsert a device for the device service
type DeviceApiPayload struct {
	HardwareThresholds *HardwareThresholdPayload `json:"hwThresholds,omitempty"`
}

type ThresholdDefinitionPayload struct {
	OkMin    *float32 `json:"okMin,omitempty"`
	OkMax    *float32 `json:"okMax,omitempty"`
	MinValue *float32 `json:"minValue,omitempty"`
	MaxValue *float32 `json:"maxValue,omitempty"`
}

type HardwareThresholdPayload struct {
	TempF           *ThresholdDefinitionPayload `json:"tempF,omitempty"`
	TempC           *ThresholdDefinitionPayload `json:"tempC,omitempty"`
	Humidity        *ThresholdDefinitionPayload `json:"humidity,omitempty"`
	Battery         *ThresholdDefinitionPayload `json:"battery,omitempty"`
	TempEnabled     bool                        `json:"tempEnabled,omitempty"`
	HumidityEnabled bool                        `json:"humidityEnabled,omitempty"`
	BatteryEnabled  bool                        `json:"batteryEnabled,omitempty"`
}

type FWPropertiesUpdatePayload struct {
	TelemetryRealtimeEnabled   bool    `json:"telemetry_realtime_enabled"`
	TelemetryRealtimeInterval  int64   `json:"telemetry_realtime_interval"`
	TelemetryRealtimeChangeGpm float64 `json:"telemetry_realtime_change_gpm"`
	TelemetryRealtimeChangePsi int64   `json:"telemetry_realtime_change_psi"`
	TelemetryBatchedEnabled    bool    `json:"telemetry_batched_enabled"`
	TelemetryBatchedInterval   int64   `json:"telemetry_batched_interval"`
	TelemetryBatchedHfEnabled  bool    `json:"telemetry_batched_hf_enabled"`
	FlodetectPostEnabled       bool    `json:"flodetect_post_enabled"`
	MenderPingDelay            int64   `json:"mender_ping_delay"`
	LogEnabled                 bool    `json:"log_enabled"`
}
