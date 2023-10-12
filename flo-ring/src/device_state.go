package main

import (
	"context"
	"strings"
	"time"
)

type deviceState struct {
	logger *Logger
	pubGW  PublicGateway
	repo   EntityStore
}

type DeviceState interface {
	BuildStateReport(ctx context.Context, userAccessToken string, directive *DirectiveMessage) (*EventMessage, error)
	GetSystemModeProperty(d *Device) *Property
	GetValveStateProperty(d *Device) *Property
	GetConnectivityProperty(d *Device) *Property
	GetSignalStrengthProperty(d *Device) *Property
	GetSignalNetworkIdentifierProperty(d *Device) *Property
	GetPendingAlertsProperty(d *Device, userAccessToken string) (*Property, error)
	EnsureCauseSource(cause, source string) (string, string)
	EnsureValveMeta(vs *ValveStateMeta) *ValveStateMeta
}

func CreateDeviceState(
	logger *Logger, repo EntityStore, pubGW PublicGateway) DeviceState {

	ds := deviceState{
		logger.CloneAsChild("deviceState"),
		pubGW,
		repo,
	}
	return &ds
}

func (ds *deviceState) EnsureCauseSource(cause, source string) (string, string) {
	if cause == "" {
		cause = "PERIODIC_POLL"
	}
	cause = strings.ToUpper(cause)
	switch cause {
	case "APP_INTERACTION":
		if source == "" {
			source = "VENDOR_APP"
		}
	case "PHYSICAL_INTERACTION":
		if source == "" {
			source = "AUTO"
		}
	case "VOICE_INTERACTION":
		if source == "" {
			source = "ALEXA_DEVICE"
		}
	}
	return cause, source
}

func (ds *deviceState) EnsureValveMeta(vs *ValveStateMeta) *ValveStateMeta {
	if vs != nil && vs.Cause != nil {
		var (
			srcIn, srcOut string
			hasSrc        = false
		)
		if vs.Cause.Source != nil {
			srcIn = vs.Cause.Source.Type
			hasSrc = true
		}
		vs.Cause.Type, srcOut = ds.EnsureCauseSource(vs.Cause.Type, srcIn)
		if hasSrc {
			vs.Cause.Source.Type = strings.ToUpper(srcOut)
		} else if srcIn == "" && srcOut != "" {
			if vs.Cause.Source == nil {
				vs.Cause.Source = &ValveStateSource{}
			}
			vs.Cause.Source.Type = strings.ToUpper(srcOut)
		}
	}
	return vs
}

func (ds *deviceState) BuildStateReport(ctx context.Context, userAccessToken string, directive *DirectiveMessage) (*EventMessage, error) {
	var (
		deviceId = directive.Directive.Endpoint.EndpointId
		dc       = deviceCriteria{Jwt: userAccessToken, Id: deviceId}
		d, err   = ds.pubGW.GetDevice(&dc)
	)
	if err != nil {
		return nil, err
	}

	if d.Valve != nil {
		ds.EnsureValveMeta(d.Valve.Meta)
	}
	go func(device *Device) {
		defer panicRecover(ds.logger, "BuildStateReport: deviceId %v (mac %v)", device.Id, device.MacAddress)
		if e := ds.repo.StoreDevices(ctx, device); e != nil {
			ds.logger.IfWarnF(e, "BuildStateReport: deviceId %v (mac %v)", device.Id, device.MacAddress)
		}
	}(d)

	props := make([]*Property, 0, 6)
	if strings.EqualFold(getEnvOrDefault("FLO_ENABLE_SYSTEM_MODE", ""), "true") {
		props = append(props, ds.GetSystemModeProperty(d))
	}
	props = append(props,
		ds.GetValveStateProperty(d),
		ds.GetConnectivityProperty(d),
		ds.GetSignalStrengthProperty(d),
		ds.GetSignalNetworkIdentifierProperty(d),
	)
	if alerts, _ := ds.GetPendingAlertsProperty(d, userAccessToken); alerts != nil {
		props = append(props, alerts)
	}
	return &EventMessage{
		Event: Event{
			Header: Header{
				MessageId:        directive.Directive.Header.MessageId,
				CorrelationToken: directive.Directive.Header.CorrelationToken,
				Namespace:        "Alexa",
				Name:             "StateReport",
				PayloadVersion:   "3",
			},
			Endpoint: &Endpoint{EndpointId: deviceId},
		},
		Context: &Context{Properties: props},
	}, nil
}

func (ds *deviceState) GetSystemModeProperty(d *Device) *Property {
	p := Property{
		Namespace:     "Alexa.ModeController",
		Name:          "systemMode",
		Instance:      "System.Modes",
		Value:         "HOME",
		TimeOfSample:  time.Now().UTC().Format(TIME_FMT_NO_MS),
		UncertaintyMs: 0,
	}
	if d.Mode != nil {
		if d.Mode.Locked {
			p.Value = "SLEEP"
		} else if d.Mode.LastKnown != "" {
			p.Value = strings.ToUpper(d.Mode.LastKnown)
		}
	}
	return &p
}

func (ds *deviceState) GetValveStateProperty(d *Device) *Property {
	p := Property{
		Namespace: "Alexa.ModeController",
		Name:      "mode",
		Instance:  "Valve.States",
		Value:     "OPEN",
		//TimeOfSample:  d.LastHeardFromTime.Format(TIME_FMT_NO_MS),
		//UncertaintyMs: int(time.Since(d.LastHeardFromTime.Time()).Milliseconds()),
		TimeOfSample:  time.Now().UTC().Format(TIME_FMT_NO_MS), //SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-4516
		UncertaintyMs: 0,
	}
	if d.Valve != nil {
		if d.Valve.LastKnown != "" {
			p.Value = strings.ToUpper(d.Valve.LastKnown)
		}
		if d.Valve.Meta != nil && d.Valve.Meta.Cause != nil && d.Valve.Meta.Cause.Source != nil && d.Valve.Meta.Cause.Source.Type != "" {
			if p.Cookie == nil {
				p.Cookie = make(map[string]interface{})
			}
			p.Cookie["source"] = strings.ToLower(d.Valve.Meta.Cause.Source.Type)
		}
	}
	return &p
}

func (ds *deviceState) GetConnectivityProperty(d *Device) *Property {
	connectivity := "UNREACHABLE"
	if d.IsConnected != nil && *d.IsConnected {
		connectivity = "OK"
	}
	return &Property{
		Namespace: "Alexa.EndpointHealth",
		Name:      "connectivity",
		Value: map[string]interface{}{
			"value": connectivity,
		},
		//TimeOfSample:  d.LastHeardFromTime.Format(TIME_FMT_NO_MS),
		//UncertaintyMs: int(time.Since(d.LastHeardFromTime.Time()).Milliseconds()),
		TimeOfSample:  time.Now().UTC().Format(TIME_FMT_NO_MS), //SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-4516
		UncertaintyMs: 0,
	}
}

func (ds *deviceState) GetSignalStrengthProperty(d *Device) *Property {
	var (
		rssi           = -100
		signalValueStr = "CRITICAL"
	)
	if d.IsConnected != nil && *d.IsConnected { //if disconnected, wifi is no good :)
		if d.Connectivity != nil {
			if rssi = (*d.Connectivity).Rssi; rssi > 0 { //enforce bounds
				rssi = 0
			} else if rssi < -100 {
				rssi = -100
			}
		}
	}

	switch {
	case rssi < -80:
		signalValueStr = "CRITICAL"
	case rssi < -60:
		signalValueStr = "LOW"
	case rssi < -40:
		signalValueStr = "OK"
	default:
		signalValueStr = "GOOD"
	}
	return &Property{
		Namespace: "Alexa.EndpointHealth",
		Name:      "signalStrength",
		Value: map[string]interface{}{
			"value": signalValueStr,
			"rssi":  rssi,
		},
		//TimeOfSample:  d.LastHeardFromTime.Format(TIME_FMT_NO_MS),
		//UncertaintyMs: int(time.Since(d.LastHeardFromTime.Time()).Milliseconds()),
		TimeOfSample:  time.Now().UTC().Format(TIME_FMT_NO_MS), //SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-4516
		UncertaintyMs: 0,
	}
}

func (ds *deviceState) GetSignalNetworkIdentifierProperty(d *Device) *Property {
	var ssid string
	if d.Connectivity != nil {
		ssid = (*d.Connectivity).Ssid
	}

	return &Property{
		Namespace: "Alexa.EndpointHealth",
		Name:      "signalNetworkIdentifier",
		Value: map[string]interface{}{
			"value": ssid,
		},
		//TimeOfSample:  d.LastHeardFromTime.Format(TIME_FMT_NO_MS),
		//UncertaintyMs: int(time.Since(d.LastHeardFromTime.Time()).Milliseconds()),
		TimeOfSample:  time.Now().UTC().Format(TIME_FMT_NO_MS), //SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-4516
		UncertaintyMs: 0,
	}
}

func (ds *deviceState) getIncidents(deviceId, accessToken string) ([]*Incident, error) {
	if arr, e := ds.pubGW.GetIncidents(deviceId, accessToken); e != nil {
		return nil, ds.logger.IfWarnF(e, "getIncidents: %v using %v", deviceId, CleanToken(accessToken))
	} else {
		return arr, nil
	}
}

const TIME_FMT_NO_MS = "2006-01-02T15:04:05Z"

func (ds *deviceState) GetPendingAlertsProperty(d *Device, userAccessToken string) (*Property, error) {
	alerts := make([]*RingAlert, 0)
	if ds.hasDevicePendingNotifications(d) {
		if incidents, e := ds.getIncidents(d.Id, userAccessToken); e != nil {
			return nil, e
		} else {
			for _, o := range incidents {
				if o == nil {
					continue
				}
				a := RingAlert{
					Methods:  []string{"SENSOR"},
					Value:    "DETECTED",
					Severity: strings.ToUpper(o.Alarm.Severity),
					Time:     o.Created.Time().UTC(),
					Alert:    o.Title,
				}
				alerts = append(alerts, &a)
			}
		}
	}

	return &Property{
		Namespace:     "Alexa.EventDetectionSensor",
		Name:          "deviceAlertsDetectionState",
		Value:         alerts,
		TimeOfSample:  time.Now().UTC().Format(TIME_FMT_NO_MS),
		UncertaintyMs: 0,
	}, nil
}

func (ds *deviceState) hasDevicePendingNotifications(d *Device) bool {
	return d.Notifications != nil &&
		d.Notifications.Pending != nil &&
		(d.Notifications.Pending.CriticalCount > 0 || d.Notifications.Pending.WarningCount > 0)
}
