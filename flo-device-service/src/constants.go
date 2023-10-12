package main

import (
	"errors"
)

// APIVersion API version
const APIVersion = "v1"

// EmptyString is the empty string value
const EmptyString = ""

// NoneValue is the string none value
const NoneValue = "none"

// DeviceServiceKey is the device service key, can be used as a collection name for Firestore, RDS table, endpoints
const DeviceServiceKey = "devices"

// DeviceIdKey is the deviceId key
const DeviceIdKey = "deviceId"

// DeviceAlreadyExistsErrorMsg is the device already exists error msg
const DeviceAlreadyExistsErrorMsg = "deviceId_%s already exists"

// NoSuchDeviceErrorMsg is no such device error message
const NoSuchDeviceErrorMsg = "deviceId_%s doesn't exist"

// FwVersionInternalPropertiesKey is the firmware version internal properties (sent from the device) key
const FwVersionInternalPropertiesKey = "fw_ver"

// SystemModeInternalPropertiesKey is the system mode internal properties (sent from the device) key
const SystemModeInternalPropertiesKey = "system_mode"

// FwWifiSsidKey is the key to the ssid from fw properties
const FwWifiSsidKey = "wifi_sta_ssid"

const SomethingWentWrongErrMsg = "Something went wrong."

var UniqueConstraintFailed = errors.New("Unique constraint failed.")
