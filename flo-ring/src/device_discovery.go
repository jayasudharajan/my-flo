package main

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"
)

type DiscoveryEndpoint struct {
	EndpointId           string                 `json:"endpointId"`
	ManufacturerName     string                 `json:"manufacturerName"`
	Description          string                 `json:"description"`
	FriendlyName         string                 `json:"friendlyName"`
	DisplayCategories    []string               `json:"displayCategories"`
	Capabilities         []*Capability          `json:"capabilities"`
	AdditionalAttributes *AdditionalAttributes  `json:"additionalAttributes,omitempty"`
	Connections          []*Connection          `json:"connections,omitempty"`
	Relationships        *Relationships         `json:"relationships,omitempty"`
	Cookie               map[string]interface{} `json:"cookie,omitempty"`
}

type Capability struct {
	Type                string                 `json:"type"`
	Interface           string                 `json:"interface"`
	Version             string                 `json:"version"`
	Instance            string                 `json:"instance,omitempty"`
	Properties          *CapabilityProperty    `json:"properties,omitempty"`
	CapabilityResources map[string]interface{} `json:"capabilityResources,omitempty"`
	Configuration       map[string]interface{} `json:"configuration,omitempty"`
}

type CapabilityProperty struct {
	Supported           []*Supported `json:"supported,omitempty"`
	ProactivelyReported *bool        `json:"proactivelyReported,omitempty"`
	Retrievable         *bool        `json:"retrievable,omitempty"`
}

type Supported struct {
	Name string `json:"name"`
}

type AdditionalAttributes struct {
	Manufacturer     string `json:"manufacturer,omitempty"`
	Model            string `json:"model,omitempty"`
	SerialNumber     string `json:"serialNumber,omitempty"`
	FirmwareVersion  string `json:"firmwareVersion,omitempty"`
	SoftwareVersion  string `json:"softwareVersion,omitempty"`
	CustomIdentifier string `json:"customIdentifier,omitempty"`
}

type Connection struct {
	Type       string `json:"type"`
	MacAddress string `json:"macAddress,omitempty"`
	HomeId     string `json:"homeId,omitempty"`
	NodeId     string `json:"nodeId,omitempty"`
	Value      string `json:"value,omitempty"`
}

type Relationships struct {
	IsConnectedBy IsConnectedBy `json:"isConnectedBy"`
}

type IsConnectedBy struct {
	EndpointId string `json:"endpointId"`
}

type DiscoveryPayload struct {
	EndpointIds []string             `json:"endpointIds,omitempty"`
	Endpoints   []*DiscoveryEndpoint `json:"endpoints"` //NOTE: don't omit!!
	Scope       *Scope               `json:"scope,omitempty"`
}

type DeviceDiscoveryAmazonConfig struct {
	ApiKey string
}

type deviceDiscovery struct {
	logger       *Logger
	amazonConfig *DeviceDiscoveryAmazonConfig
	entityStore  EntityStore
	keyDur       KeyPerDuration
	pubGW        PublicGateway
}

type DeviceDiscovery interface {
	Discover(ctx context.Context, accessToken string, userId string, directive *DirectiveMessage) *EventMessage
	BuildAddOrUpdateReportForDevice(ctx context.Context, deviceId string) (*EventMessage, error)
	BuildAddOrUpdateReportForLocation(ctx context.Context, locationId string) (*EventMessage, error)
	BuildDeleteReportForDevice(ctx context.Context, d *Device) (*EventMessage, error)
	BuildDeleteReportForLocation(ctx context.Context, l *Location) (*EventMessage, error)
}

const manufacturer = "Flo by Moen"
const deviceTypePrefix = "flo_device_v"

var _deviceDiscoveryKeyDur = CreateKeyPerDuration(time.Hour * 4) //static singleton

func CreateDeviceDiscovery(
	logger *Logger,
	amazonConfig *DeviceDiscoveryAmazonConfig,
	ds EntityStore,
	pubGW PublicGateway) DeviceDiscovery {

	l := logger.CloneAsChild("deviceDiscovery")
	dd := deviceDiscovery{
		l,
		amazonConfig,
		ds,
		_deviceDiscoveryKeyDur,
		pubGW}
	return &dd
}

func (dd *deviceDiscovery) Discover(ctx context.Context, userAccessToken string, userId string, req *DirectiveMessage) *EventMessage {
	p := DiscoveryPayload{Endpoints: make([]*DiscoveryEndpoint, 0)}
	if userLocs, e := dd.pubGW.UserLocations(userId, userAccessToken); e != nil {
		dd.logger.Error("discover: error fetching devices for user %s - %v", userId, e)
		return req.toEvent(ErrorPayload{
			Type:    "INTERNAL_ERROR",
			Message: "get user devices failed",
		})
	} else {
		for _, loc := range userLocs {
			p.Endpoints = append(p.Endpoints, dd.locationToEndpoints(loc)...)
			go dd.storeDevices(ctx, "Discover userId "+userId, loc.Devices...)
		}
		return req.toEvent(p)
	}
}

func (dd *deviceDiscovery) storeDevices(ctx context.Context, reason string, devices ...*Device) {
	defer panicRecover(dd.logger, "storeDevices: %v count=%v", reason, len(devices))
	for _, d := range devices {
		if !dd.isDeviceDiscoverable(d) {
			continue
		}
		if e := dd.entityStore.StoreDevices(ctx, d); e != nil {
			dd.logger.IfWarnF(e, "storeDevices: for %v (mac %v) failed because %v", d.Id, d.MacAddress, reason)
		}
	}
}

func (dd *deviceDiscovery) traceSampleLog(key, msg string, args ...interface{}) {
	ll := LL_DEBUG
	if !dd.keyDur.Check(key, time.Hour) {
		ll = LL_TRACE
	}
	dd.logger.Log(ll, msg, args...)
}

func (dd *deviceDiscovery) BuildAddOrUpdateReportForDevice(ctx context.Context, deviceId string) (*EventMessage, error) {
	var (
		dc              = deviceCriteria{Id: deviceId, ExpandLoc: true}
		fullDevice, err = dd.pubGW.GetDevice(&dc)
	)
	if err != nil {
		return nil, fmt.Errorf("buildAddOrUpdateReportForDevice: error while retrieving device: %s - %v", deviceId, err)
	} else if !dd.isDeviceDiscoverable(fullDevice) {
		dd.traceSampleLog("no-disco-dev:"+fullDevice.Id,
			"BuildAddOrUpdateReportForDevice: device %s is NONE_DISCOVERABLE", fullDevice.Id)
		return nil, nil
	} else if !dd.isAnyUserIntegratedWithRing(ctx, fullDevice.Location.Users) {
		dd.traceSampleLog("ring:"+fullDevice.Location.Id,
			"BuildAddOrUpdateReportForDevice: location %s users are MISSING_REGISTRATION", fullDevice.Location.Id)
		return nil, nil
	}

	go dd.storeDevices(ctx, "BuildAddOrUpdateReportForDevice: "+deviceId, fullDevice)
	p := &DiscoveryPayload{
		Endpoints: []*DiscoveryEndpoint{
			dd.buildDeviceEndpoint(fullDevice.Location, fullDevice),
		},
	}
	return dd.buildAddOrUpdateReport(p), nil
}

func (dd *deviceDiscovery) BuildAddOrUpdateReportForLocation(ctx context.Context, locationId string) (*EventMessage, error) {
	fullLocation, err := dd.pubGW.Location(locationId, "")
	if err != nil {
		return nil, fmt.Errorf("buildAddOrUpdateReportForLocation: error while retrieving location: %s - %v", locationId, err)
	}
	if !dd.isAnyUserIntegratedWithRing(ctx, fullLocation.Users) {
		dd.logger.Debug("buildAddOrUpdateReportForLocation: location %s users are MISSING_REGISTRATION", fullLocation.Id)
		return nil, nil
	}

	discoveries := make([]*Device, 0, len(fullLocation.Devices))
	for _, d := range fullLocation.Devices {
		if dd.isDeviceDiscoverable(d) {
			discoveries = append(discoveries, d)
		}
	}
	if len(discoveries) == 0 {
		return nil, nil
	}
	fullLocation.Devices = discoveries

	go dd.storeDevices(ctx, "BuildAddOrUpdateReportForLocation: "+locationId, fullLocation.Devices...)
	p := &DiscoveryPayload{
		Endpoints: dd.locationToEndpoints(fullLocation),
	}
	return dd.buildAddOrUpdateReport(p), nil
}

func (dd *deviceDiscovery) BuildDeleteReportForDevice(ctx context.Context, d *Device) (*EventMessage, error) {
	if d != nil {
		count, err := dd.entityStore.DeleteDevices(ctx, d)
		if err != nil {
			return nil, err
		}
		if count > 0 {
			return dd.buildDeleteReport([]string{d.Id}), nil
		}
	}
	return nil, nil
}

func (dd *deviceDiscovery) BuildDeleteReportForLocation(ctx context.Context, l *Location) (*EventMessage, error) {
	if l != nil {
		count, err := dd.entityStore.DeleteDevices(ctx, l.Devices...)
		if err != nil {
			return nil, err
		}
		var deviceIds []string
		if count > 0 {
			for _, d := range l.Devices {
				deviceIds = append(deviceIds, d.Id)
			}
			return dd.buildDeleteReport(deviceIds), nil
		}
	}
	return nil, nil
}

func (dd *deviceDiscovery) isAnyUserIntegratedWithRing(ctx context.Context, users []*User) bool {
	for _, u := range users {
		if exists, err := dd.entityStore.UserExists(ctx, u.Id); err != nil {
			dd.logger.Warn("isAnyUserIntegratedWithRing: error checking user %s - %v", u.Id, err)
		} else if exists {
			return true
		}
	}
	return false
}

func (dd *deviceDiscovery) buildDeleteReport(deviceIds []string) *EventMessage {
	p := &DiscoveryPayload{
		EndpointIds: deviceIds,
	}
	return dd.buildDiscoveryEvent("DeleteReport", p)
}

func (dd *deviceDiscovery) buildAddOrUpdateReport(p *DiscoveryPayload) *EventMessage {
	return dd.buildDiscoveryEvent("AddOrUpdateReport", p)
}

func (dd *deviceDiscovery) buildDiscoveryEvent(name string, p *DiscoveryPayload) *EventMessage {
	p.Scope = &Scope{
		Type:   "ApiKey",
		ApiKey: dd.amazonConfig.ApiKey,
	}
	return &EventMessage{
		Event: Event{
			Header: Header{
				Namespace:      "Alexa.Discovery",
				Name:           name,
				PayloadVersion: "3",
				MessageId:      newUUID(),
			},
			Payload: p,
		},
	}
}

func isDeviceTypeDiscoverable(deviceType string) bool {
	dt := strings.ToLower(deviceType)
	if ix := strings.Index(dt, deviceTypePrefix); ix == 0 {
		if ver, _ := strconv.ParseFloat(dt[len(deviceTypePrefix):], 64); ver >= 2 {
			return true
		}
	}
	return false
}

func (dd *deviceDiscovery) isDeviceDiscoverable(d *Device) bool {
	return isDeviceTypeDiscoverable(d.DeviceType)
}

func (dd *deviceDiscovery) locationToEndpoints(l *Location) []*DiscoveryEndpoint {
	var discoveryEndpoints []*DiscoveryEndpoint
	for _, d := range l.Devices {
		// Temporarily filter out Pucks. Remove/adapt this filter once we support Pucks.
		if dd.isDeviceDiscoverable(d) {
			ep := dd.buildDeviceEndpoint(l, d)
			dd.patchSerialNum(ep)
			discoveryEndpoints = append(discoveryEndpoints, ep)
		}
	}
	return discoveryEndpoints
}

func (dd *deviceDiscovery) patchSerialNum(ep *DiscoveryEndpoint) {
	if ep == nil {
		return
	}
	if sn, ok := ep.Cookie["serialNumber"]; ok && (dd.logger.isDebug || sn == "") {
		defer panicRecover(dd.logger, "patchSerialNum: %v", ep.EndpointId) //continue on failure
		var (
			snOK = false
			ll   = IfLogLevel(dd.logger.isDebug, LL_INFO, LL_NOTICE)
		)
		if mac, y := ep.Cookie["macAddress"]; y && mac != nil {
			if serial, er := dd.pubGW.GetSerial(fmt.Sprint(mac)); er == nil && serial != nil && serial.Serial != "" {
				ep.Cookie["serialNumber"] = serial.Serial
				snOK = true
			}
		}
		dd.logger.Log(IfLogLevel(snOK, ll, ll+1), "Discover: missing_serial for %v | found=%v", ep.EndpointId, snOK)
	}
}

func (dd *deviceDiscovery) buildDeviceEndpoint(l *Location, d *Device) *DiscoveryEndpoint {
	return &DiscoveryEndpoint{
		EndpointId:        d.Id,
		ManufacturerName:  manufacturer,
		Description:       "Flo by Moen Smart Water Shutoff",
		FriendlyName:      d.Nickname,
		DisplayCategories: []string{"VALVE"},
		Cookie:            dd.buildCookie(l, d),
		Capabilities:      dd.buildDeviceCapabilities(),
	}
}

func (dd *deviceDiscovery) buildDeviceCapabilities() []*Capability {
	caps := make([]*Capability, 0, 4)
	if strings.EqualFold(getEnvOrDefault("FLO_ENABLE_SYSTEM_MODE", ""), "true") {
		caps = append(caps, dd.buildSystemModeControllerCapability())
	}
	caps = append(caps,
		dd.buildValveStateControllerCapability(),
		dd.buildEndpointHealthCapability(),
		dd.buildEventDetectionCapability(),
	)
	return caps
}

func (_ *deviceDiscovery) buildSystemModeControllerCapability() *Capability {
	proactivelyReported := true
	retrievable := true
	return &Capability{
		Type:      "AlexaInterface",
		Interface: "Alexa.ModeController",
		Instance:  "System.Modes",
		Version:   "3",
		Properties: &CapabilityProperty{
			Supported: []*Supported{
				{Name: "systemMode"},
			},
			ProactivelyReported: &proactivelyReported,
			Retrievable:         &retrievable,
		},
		CapabilityResources: map[string]interface{}{
			"friendlyNames": []map[string]interface{}{
				{
					"@type": "text",
					"value": map[string]interface{}{"text": "System Modes"},
				},
			},
		},
		Configuration: map[string]interface{}{
			"ordered": false,
			"supportedModes": []map[string]interface{}{
				{
					"value": "Modes.Home",
					"modeResources": map[string]interface{}{
						"friendlyNames": []map[string]interface{}{
							{
								"@type": "text",
								"value": map[string]interface{}{"text": "Home"},
							},
						},
					},
				},
				{
					"value": "Modes.Away",
					"modeResources": map[string]interface{}{
						"friendlyNames": []map[string]interface{}{
							{
								"@type": "text",
								"value": map[string]interface{}{"text": "Away"},
							},
						},
					},
				},
				{
					"value": "Modes.Sleep",
					"modeResources": map[string]interface{}{
						"friendlyNames": []map[string]interface{}{
							{
								"@type": "text",
								"value": map[string]interface{}{"text": "Sleep"},
							},
						},
					},
				},
			},
		},
	}
}

func (_ *deviceDiscovery) buildValveStateControllerCapability() *Capability {
	proactivelyReported := true
	retrievable := true
	return &Capability{
		Type:      "AlexaInterface",
		Interface: "Alexa.ModeController",
		Instance:  "Valve.States",
		Version:   "3",
		Properties: &CapabilityProperty{
			Supported: []*Supported{
				{Name: "mode"},
			},
			ProactivelyReported: &proactivelyReported,
			Retrievable:         &retrievable,
		},
		CapabilityResources: map[string]interface{}{
			"friendlyNames": []map[string]interface{}{
				{
					"@type": "text",
					"value": map[string]interface{}{"text": "Valve States"},
				},
			},
		},
		Configuration: map[string]interface{}{
			"ordered": false,
			"supportedModes": []map[string]interface{}{
				{
					"value": "States.Open",
					"modeResources": map[string]interface{}{
						"friendlyNames": []map[string]interface{}{
							{
								"@type": "text",
								"value": map[string]interface{}{"text": "Open"},
							},
						},
					},
				},
				{
					"value": "States.Closed",
					"modeResources": map[string]interface{}{
						"friendlyNames": []map[string]interface{}{
							{
								"@type": "text",
								"value": map[string]interface{}{"text": "Closed"},
							},
						},
					},
				},
				{
					"value": "States.Broken",
					"modeResources": map[string]interface{}{
						"friendlyNames": []map[string]interface{}{
							{
								"@type": "text",
								"value": map[string]interface{}{"text": "Broken"},
							},
						},
					},
				},
			},
		},
	}
}

func (dd *deviceDiscovery) buildEndpointHealthCapability() *Capability {
	proactivelyReported := true
	retrievable := true
	return &Capability{
		Type:      "AlexaInterface",
		Interface: "Alexa.EndpointHealth",
		Version:   "3",
		Properties: &CapabilityProperty{
			Supported: []*Supported{
				{Name: "connectivity"},
				{Name: "signalStrength"},
				{Name: "signalNetworkIdentifier"},
			},
			ProactivelyReported: &proactivelyReported,
			Retrievable:         &retrievable,
		},
	}
}

func (dd *deviceDiscovery) buildEventDetectionCapability() *Capability {
	proactivelyReported := true
	retrievable := true
	return &Capability{
		Type:      "AlexaInterface",
		Interface: "Alexa.EventDetectionSensor",
		Version:   "3",
		Properties: &CapabilityProperty{
			Supported: []*Supported{
				{Name: "deviceAlertsDetectionState"},
			},
			ProactivelyReported: &proactivelyReported,
			Retrievable:         &retrievable,
		},
		Configuration: map[string]interface{}{
			"detectionMethods": []string{"SENSOR"},
			"detectionModes": map[string]interface{}{
				"deviceAlerts": map[string]interface{}{
					"featureAvailability": "ENABLED",
					"supportsNotDetected": true,
				},
			},
		},
	}
}

func (dd *deviceDiscovery) buildCookie(l *Location, d *Device) map[string]interface{} {
	fwv := d.FirmwareVersion
	if fwv == "" {
		fwv = "0.0.0"
	}
	res := map[string]interface{}{
		"macAddress":      d.MacAddress,
		"model":           d.DeviceModel,
		"serialNumber":    d.SerialNumber,
		"firmwareVersion": fwv,
		"location":        l.Nickname,
	}
	if d.Connectivity != nil {
		if d.Connectivity.Ssid != "" {
			res["wifiName"] = d.Connectivity.Ssid
		}
	}
	return res
}
