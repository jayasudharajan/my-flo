package main

import (
	"fmt"
	"strings"
	"time"
)

type MessageExchange struct {
	Time      *time.Time        `json:"time,omitempty"`
	Directive *DirectiveMessage `json:"directive,omitempty"`
	Event     *EventMessage     `json:"event,omitempty"`
}

// Ring
type Header struct {
	Namespace        string `json:"namespace"`
	Name             string `json:"name"`
	Instance         string `json:"instance,omitempty"`
	MessageId        string `json:"messageId"`
	CorrelationToken string `json:"correlationToken,omitempty"`
	PayloadVersion   string `json:"payloadVersion"`
}

func (h Header) String() string {
	return tryToJson(h)
}

type Endpoint struct {
	EndpointId string `json:"endpointId,omitempty"`
	Scope      *Scope `json:"scope,omitempty"`
}

type Property struct {
	Namespace     string                 `json:"namespace"`
	Name          string                 `json:"name"`
	Instance      string                 `json:"instance,omitempty"`
	Value         interface{}            `json:"value"`
	TimeOfSample  string                 `json:"timeOfSample"`
	UncertaintyMs int                    `json:"uncertaintyInMilliseconds"`
	Cookie        map[string]interface{} `json:"cookie,omitempty"`
}

type Context struct {
	Properties []*Property `json:"properties"`
}

type Payload interface{}

type Scope struct {
	Type              string `json:"type,omitempty"`
	Token             string `json:"token,omitempty"`
	ApiKey            string `json:"apiKey,omitempty"`
	AccountIdentifier string `json:"accountIdentifier,omitempty"`
}

type ScopePayload struct {
	Scope Scope `json:"scope"`
}

type ErrorPayload struct {
	Type    string `json:"type"`
	Message string `json:"message"`
}

type DeferredPayload struct {
	EstimatedDeferral int `json:"estimatedDeferralInSeconds"`
}

type ChangeReportPayload struct {
	Change ChangeReport `json:"change"`
}

//type ReportStatePayload struct {
//	Method string `json:"method"`
//}

type ChangeReport struct {
	Cause      ChangeCause `json:"cause"`
	Properties []*Property `json:"properties"`
}

type ChangeCause struct {
	Type string `json:"type"`
}

type Event struct {
	Header   Header    `json:"header"`
	Endpoint *Endpoint `json:"endpoint,omitempty"`
	Payload  Payload   `json:"payload,omitempty"`
}

func (ev *Event) GetEndpointIds() []string {
	res := make([]string, 0)
	if ev.Endpoint != nil && ev.Endpoint.EndpointId != "" {
		res = append(res, ev.Endpoint.EndpointId)
	} else {
		switch p := ev.Payload.(type) {
		case *DiscoveryPayload:
			if len(p.EndpointIds) != 0 {
				res = append(res, p.EndpointIds...)
			} else {
				for _, ep := range p.Endpoints {
					if ep.EndpointId != "" {
						res = append(res, ep.EndpointId)
					}
				}
			}
		}
	}
	if len(res) > 1 {
		unique := make(map[string]bool)
		for _, id := range res {
			unique[id] = true
		}
		res = res[:0]
		for k, _ := range unique {
			res = append(res, k)
		}
	}
	return res
}

type Directive struct {
	Header   Header    `json:"header"`
	Endpoint *Endpoint `json:"endpoint,omitempty"`
	Payload  Payload   `json:"payload,omitempty"`
}

type EventMessage struct {
	Event   Event    `json:"event"`
	Context *Context `json:"context,omitempty"`
}

type DirectiveMessage struct {
	Directive Directive `json:"directive"`
	Context   *Context  `json:"context,omitempty"`
}

func (d *DirectiveMessage) toEvent(p Payload) *EventMessage {
	return &EventMessage{
		Event: Event{
			Header: Header{
				Namespace:        d.Directive.Header.Namespace,
				Name:             d.Directive.Header.Name + ".Response",
				PayloadVersion:   d.Directive.Header.PayloadVersion,
				MessageId:        d.Directive.Header.MessageId,
				CorrelationToken: d.Directive.Header.CorrelationToken,
			},
			Payload: p,
		},
	}
}

func (d *DirectiveMessage) toDeferred(deferralInSecs int) *EventMessage {
	return &EventMessage{
		Event: Event{
			Header: Header{
				Namespace:        "Alexa",
				Name:             "DeferredResponse",
				PayloadVersion:   d.Directive.Header.PayloadVersion,
				MessageId:        d.Directive.Header.MessageId,
				CorrelationToken: d.Directive.Header.CorrelationToken,
			},
			Payload: DeferredPayload{
				EstimatedDeferral: deferralInSecs,
			},
		},
	}
}

// Public Gateway
type Auth struct {
	Type  string
	Token string
}

type User struct {
	Id        string `json:"id"`
	Email     string `json:"email"`
	FirstName string `json:"firstName"`
	LastName  string `json:"lastName"`
}

type Locations struct {
	Total int         `json:"total"`
	Page  int         `json:"page"`
	Items []*Location `json:"items"`
}

type Location struct {
	Id         string    `json:"id"`
	Nickname   string    `json:"nickname"`
	Address    string    `json:"address"`
	City       string    `json:"city"`
	PostalCode string    `json:"postalCode"`
	State      string    `json:"state"`
	Country    string    `json:"country"`
	Devices    []*Device `json:"devices"`
	Users      []*User   `json:"users,omitempty"`
}

type BaseDevice struct {
	Id         *string `json:"id,omitempty"`
	MacAddress *string `json:"macAddress,omitempty"`
}

func (d *BaseDevice) SetId(id string) {
	if d == nil {
		return
	}
	d.Id = &id
}

func (d *BaseDevice) GetId() string {
	if d == nil || d.Id == nil {
		return ""
	}
	return *d.Id
}

func (d *BaseDevice) SetMac(mac string) {
	if d == nil {
		return
	}
	d.MacAddress = &mac
}

func (d *BaseDevice) GetMac() string {
	if d == nil || d.MacAddress == nil {
		return ""
	}
	return *d.MacAddress
}

func (bd BaseDevice) String() string {
	return tryToJson(bd)
}

type Device struct {
	Id                string         `json:"id,omitempty"`
	MacAddress        string         `json:"macAddress,omitempty"`
	Nickname          string         `json:"nickname,omitempty"`
	DeviceModel       string         `json:"deviceModel,omitempty"`
	DeviceType        string         `json:"deviceType,omitempty"`
	SerialNumber      string         `json:"serialNumber,omitempty"`
	FirmwareVersion   string         `json:"fwVersion,omitempty"`
	IsConnected       *bool          `json:"isConnected,omitempty"`
	LastHeardFromTime *PubGwTime     `json:"lastHeardFromTime,omitempty"`
	Connectivity      *Connectivity  `json:"connectivity,omitempty"`
	Notifications     *Notifications `json:"notifications,omitempty"`
	Location          *Location      `json:"location,omitempty"`
	Valve             *Valve         `json:"valve,omitempty"`
	Mode              *SystemMode    `json:"systemMode,omitempty"`
}

type SystemMode struct {
	Locked        bool   `json:"isLocked"`
	ShouldInherit bool   `json:"shouldInherit"`
	LastKnown     string `json:"lastKnown"`
	Target        string `json:"target"`
}

type Notifications struct {
	Pending *PendingNotifications `json:"pending"`
}

type PendingNotifications struct {
	InfoCount     int           `json:"infoCount"`
	CriticalCount int           `json:"criticalCount"`
	WarningCount  int           `json:"warningCount"`
	Alarms        []*AlarmCount `json:"alarmCount,omitempty"`
}

func (pn *PendingNotifications) GetAlarmCounts(severity string) []*AlarmCount {
	res := make([]*AlarmCount, 0)
	for _, a := range pn.Alarms {
		if strings.EqualFold(a.Severity, severity) {
			res = append(res, a)
		}
	}
	return res
}

type AlarmCount struct {
	Id       int    `json:"id"`
	Severity string `json:"severity"`
	Count    int    `json:"count"`
}

// SEE: https://api-gw-dev.flocloud.co/docs/#/Incidents/get_api_v2_incidents
type Incident struct {
	Id         string     `json:"id"`
	Alarm      AlarmCount `json:"alarm"`
	Title      string     `json:"displayTitle"`
	Created    PubGwTime  `json:"createAt"`
	LocationId string     `json:"locationId"`
	SystemMode string     `json:"systemMode"`
	//Message    string `json:"displayMessage"`
	//Updated TimeNoTZ `json:"updateAt"`
	//DeviceId string `json:"deviceId"`
}

type incidentResp struct {
	Items []*Incident `json:"items,omitempty"`
	//Total int32       `json:"total,omitempty"`
}

type ValveStateSource struct {
	Id   string `json:"id,omitempty"`
	Type string `json:"type,omitempty"`
	Name string `json:"name,omitempty"`
}

type ValveStateCause struct {
	Type   string            `json:"type"`
	Source *ValveStateSource `json:"source,omitempty"`
}

type ValveStateMeta struct {
	Cause *ValveStateCause `json:"cause,omitempty"`
}

type Valve struct {
	Target    string          `json:"target,omitempty"`
	LastKnown string          `json:"lastKnown,omitempty"`
	Meta      *ValveStateMeta `json:"meta,omitempty"`
}

type Connectivity struct {
	Ssid string `json:"ssid,omitempty"`
	Rssi int    `json:"rssi,omitempty"`
}

type Alert struct {
	Id     string `json:"id"`
	Status string `json:"status,omitempty"`
	Reason string `json:"reason,omitempty"`
	//Resolved PubGwTime  `json:"resolutionDate,omitempty"`
	Updated PubGwTime  `json:"updateAt,omitempty"`
	Created PubGwTime  `json:"createAt,omitempty"`
	Alarm   Alarm      `json:"alarm"`
	Device  BaseDevice `json:"device"`
}

func (a Alert) String() string {
	dev := "UnknownDevice"
	if did := Str(a.Device.Id); did != "" {
		dev = did
	} else if mac := Str(a.Device.MacAddress); mac != "" {
		dev = mac
	}
	return fmt.Sprintf("Alert#%s->%v for %v", a.Id, a.Alarm, dev)
}

type Alarm struct {
	Id          int    `json:"id"`
	Name        string `json:"name,omitempty"`
	Display     string `json:"displayName,omitempty"`
	Description string `json:"description,omitempty"`
	Severity    string `json:"severity"`
}

func (a Alarm) String() string {
	n := a.Name
	if n == "" {
		n = a.Display
	}
	if n == "" {
		n = a.Description
	}
	return fmt.Sprintf("Alarm:%v[%s]->%q", a.Id, a.Severity, n)
}

type ValidationErr struct {
	Message string `json:"message,omitempty"`
}

func (e *ValidationErr) Error() string {
	if e == nil {
		return ""
	}
	return e.Message
}

type RingAlert struct {
	Value    string    `json:"value"`
	Methods  []string  `json:"detectionMethods,omitempty"`
	Severity string    `json:"severity"`
	Alert    string    `json:"alert"`
	Time     time.Time `json:"timeOfAlert"`
}

func (r RingAlert) String() string {
	return tryToJson(r)
}

type ScanDevice struct {
	Id      string    `json:"deviceId"`
	Mac     string    `json:"mac"`
	Created time.Time `json:"created"`
}

func (sd ScanDevice) String() string {
	return fmt.Sprintf("(%s %s)", sd.Mac, sd.Id)
}

type ScanUser struct {
	Id      string    `json:"userId"`
	Created time.Time `json:"created"`
}

func (su ScanUser) String() string {
	return fmt.Sprintf("%q", su.Id)
}

type CleanReq struct {
	MacStart string `json:"macStart"`
	Limit    int32  `json:"limit"`
	Force    bool   `json:"force"`
}

func (c CleanReq) String() string {
	return tryToJson(c)
}
