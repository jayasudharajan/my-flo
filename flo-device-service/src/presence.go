package main

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"github.com/blang/semver"
	"github.com/labstack/gommon/log"
)

const (
	ACTION_ACTIVATED string = "activated"
	ACTION_REPORT    string = "report"
	ACTION_DELETE    string = "delete"
	TYPE_USER        string = "user"
)

type PresenceMessage struct {
	Id         string            `json:"id,omitempty"`
	Action     string            `json:"action,omitempty"`
	Date       time.Time         `json:"date,omitempty"`
	IpAddress  string            `json:"ipAddress,omitempty"`
	UserId     string            `json:"userId,omitempty"`
	Type       string            `json:"type,omitempty"`
	TTL        int               `json:"ttl,omitempty"`
	AppName    string            `json:"appName,omitempty"`
	AppVersion string            `json:"appVersion,omitempty"`
	Expire     time.Time         `json:"expire,omitempty"`
	UserData   *PresenceUserInfo `json:"userData,omitempty"`
}

type PresenceUserInfo struct {
	Id              string                  `json:"id,omitempty"`
	UnitSystem      string                  `json:"unitSystem,omitempty"`
	Locale          string                  `json:"locale,omitempty"`
	EnabledFeatures []string                `json:"enabledFeatures,omitempty"`
	Locations       []*PresenceLocationInfo `json:"locations,omitempty"`
	Account         *PresenceAccountInfo    `json:"account,omitempty"`
}

type PresenceAccountInfo struct {
	Id string `json:"id,omitempty"`
}

type PresenceLocationInfo struct {
	Id       string                `json:"id,omitempty"`
	Devices  []*PresenceDeviceInfo `json:"devices,omitempty"`
	Timezone string                `json:"timezone,omitempty"`
	Country  string                `json:"country,omitempty"`
}

type PresenceDeviceInfo struct {
	Id           string `json:"id,omitempty"`
	MacAddress   string `json:"macAddress,omitempty"`
	DeviceModel  string `json:"deviceModel,omitempty"`
	DeviceType   string `json:"deviceType,omitempty"`
	FwVersion    string `json:"fwVersion,omitempty"`
	SerialNumber string `json:"serialNumber,omitempty"`
}

const minFwVersionStr = "3.5.14"

var _minFwVersion semver.Version

func init() {
	_minFwVersion, _ = semver.Make(minFwVersionStr)
}

func ProcessPresenceKafkaMessage(ctx context.Context, payload []byte) {
	presence, err := unmarshalPresencePayload(payload)
	if err != nil {
		log.Error("ProcessPresenceKafkaMessage Error ", err.Error())
		return
	}

	if presence.Type != TYPE_USER ||
		presence.Action != ACTION_ACTIVATED ||
		presence.UserData == nil ||
		len(presence.UserData.Locations) == 0 {
		return
	}

	ProcessPresence(ctx, &presence)
}

func unmarshalPresencePayload(requestPayload []byte) (PresenceMessage, error) {
	payload := PresenceMessage{}
	err := json.Unmarshal(requestPayload, &payload)
	if err != nil {
		return PresenceMessage{}, err
	}
	return payload, nil
}

func ProcessPresence(ctx context.Context, presence *PresenceMessage) {
	if presence == nil || presence.UserData == nil || len(presence.UserData.Locations) == 0 {
		return
	}

	userId := presence.UserId
	logDebug("ProcessPresence: processing presence for userId %s", userId)

	deviceIds := make([]string, 0)
	for _, loc := range presence.UserData.Locations {
		for _, dev := range loc.Devices {
			if dev == nil {
				continue
			}

			clean := strings.TrimSpace(strings.ToLower(dev.MacAddress))

			if len(clean) != 12 {
				continue
			}

			deviceIds = append(deviceIds, clean)
		}
	}

	if len(deviceIds) == 0 {
		return
	}

	for _, deviceId := range deviceIds {
		device, err := postgresRepo.GetDevice(ctx, deviceId)

		if err != nil {
			logError("ProcessPresence: failed retrieving device %s", deviceId)
			continue
		}

		if device.FwVersion != nil && *device.FwVersion != "" {
			deviceVersion, err := semver.Make(*device.FwVersion)

			if err != nil {
				logError("ProcessPresence: unable to parse device %s version %s", deviceId, *device.FwVersion)
				continue
			}

			if !deviceVersion.GT(_minFwVersion) {
				logDebug("ProcessPresence: skipping real-time telemetry for device %v. FW Version: %v", deviceId, *device.FwVersion)
				continue
			}

			isRealTimeTelemetryPeriodExpired, err := redisRepo.IsRealTimeTelemetryPeriodExpired(ctx, deviceId)
			if err != nil {
				logError("ProcessPresence: error while retrieving real-time telemetry period for device %s", deviceId)
				continue
			}

			if !isRealTimeTelemetryPeriodExpired {
				logDebug("ProcessPresence: skipping real-time telemetry for device %v. Period not expired.", deviceId)
				continue
			}

			EnableDeviceRealtimeTelemetry(ctx, deviceId, fwProperties_TelemetryRealtimeTimeoutSeconds)
		}
	}

	err := redisRepo.SaveDevicePresence(ctx, deviceIds)
	if err != nil {
		logError("ProcessPresence. Redis Error. %v", err.Error())
		return
	}

	return
}

func EnableDeviceRealtimeTelemetry(ctx context.Context, deviceId string, seconds int) {
	if seconds <= 0 {
		logWarn("EnableDeviceRealtimeTelemetry: Device %v for %v sec(s) is invalid. must be > 0", deviceId, seconds)
		return
	}

	logDebug("EnableDeviceRealtimeTelemetry: Device %v for %v sec(s)", deviceId, seconds)

	requestId, _ := GenerateUuid()
	fwPropertiesSetter := FwPropertiesSetter{
		Id:        deviceId,
		RequestId: requestId,
		FwProperties: map[string]interface{}{
			fwProperties_TelemetryRealtimeTimeoutKey: seconds,
		},
	}
	fwPropertiesSetterBytes, _ := json.Marshal(fwPropertiesSetter)

	PublishToFwPropsMqttTopic(ctx, deviceId, QOS_1, fwPropertiesSetterBytes, "set")
}
