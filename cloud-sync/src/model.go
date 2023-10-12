package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

const (
	EVENT_ACTION_CREATED      = "created"
	EVENT_ACTION_UPDATED      = "updated"
	EVENT_ACTION_DELETED      = "deleted"
	EVENT_ACTION_LINKED       = "linked"
	EVENT_ACTION_UNLINKED     = "unlinked"
	EVENT_TYPE_LOCATION       = "location"
	EVENT_TYPE_USER           = "user"
	EVENT_TYPE_ALERT          = "alert"
	EVENT_TYPE_ALARM_SETTINGS = "alarm_settings"
	EVENT_TYPE_DEVICE         = "device"
	HTTP_GET                  = "GET"
	HTTP_POST                 = "POST"
	HTTP_DELETE               = "DELETE"
)

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

type EventWrapper struct {
	Header   *EventRequestHeader `json:"header" validate:"required"`
	Request  *EventRequestBody   `json:"request" validate:"required"`
	Response *EventResponseBody  `json:"response,omitempty"`
}

func (h EventRequestHeader) String() string {
	return fmt.Sprintf("[header: %v %v %v]", h.RequestID, h.Timestamp, h.Source)
}

func (b EventRequestBody) String() string {
	payload := ""
	if b.Payload == nil {
		payload = "[payload: nil]"
	} else {
		payload = fmt.Sprintf("[payload: len(%v) %v]", len(*b.Payload), string(*b.Payload))
	}

	return fmt.Sprintf("[request: %v %v %v]", b.Entity, b.Action, payload)
}

func (b EventResponseBody) String() string {
	payload := ""
	if b.Payload == nil {
		payload = "[payload: nil]"
	} else {
		payload = fmt.Sprintf("[payload: len(%v) %v]", len(*b.Payload), string(*b.Payload))
	}

	return fmt.Sprintf("[request: %v %v %v %v]", b.Timestamp, b.Code, b.Message, payload)
}

func (w EventWrapper) String() string {
	return fmt.Sprintf("[eventwrapper:%v %v %v]", w.Header, w.Request, w.Response)
}

const (
	ENTITY_ACTIVITY_ACTION_LINKED   = "linked"
	ENTITY_ACTIVITY_ACTION_UNLINKED = "unlinked"
)

type FloActivityLocation struct {
	ID         string     `json:"id,omitempty"`
	Address    string     `json:"address,omitempty"`
	Address2   string     `json:"address2,omitempty"`
	City       string     `json:"city,omitempty"`
	State      string     `json:"state,omitempty"`
	PostalCode string     `json:"postalCode,omitempty"`
	Country    string     `json:"country,omitempty"`
	Nickname   string     `json:"nickname,omitempty"`
	Account    *FloEntity `json:"account,omitempty"`
}

type FloActivityDevice struct {
	ID                string               `json:"id,omitempty"`
	MacAddress        string               `json:"macAddress,omitempty"`
	DeviceModel       string               `json:"deviceModel,omitempty"`
	DeviceType        string               `json:"deviceType,omitempty"`
	Nickname          string               `json:"nickname,omitempty"`
	SerialNumber      string               `json:"serialNumber,omitempty"`
	FWVersion         string               `json:"fwVersion,omitempty"`
	LastHeardFromTime string               `json:"lastHeardFromTime,omitempty"`
	Location          *FloActivityLocation `json:"location,omitempty"`
}

type FloEntity struct {
	ID string `json:"id"`
}

type FloActivityUser struct {
	ID          string     `json:"id"`
	Email       string     `json:"email"`
	PhoneMobile string     `json:"phoneMobile,omitempty"`
	FirstName   string     `json:"firstName,omitempty"`
	LastName    string     `json:"lastName,omitempty"`
	IsActive    bool       `json:"isActive"`
	Account     *FloEntity `json:"account,omitempty"`
}

type FloActivityAlert struct {
	ID             string     `json:"id"`
	FloUserId      string     `json:"userId"`
	MoenUserId     string     `json:"moenUserId"`
	Alarm          FloAlarm   `json:"alarm"`
	Device         BaseDevice `json:"device"`
	Status         string     `json:"status"`
	Reason         string     `json:"reason"`
	LocationId     string     `json:"locationId"`
	ResolutionDate string     `json:"resolutionDate"`
	UpdateAt       string     `json:"updateAt"`
	CreateAt       string     `json:"createAt"`
}

type FloActivityUserAlertSettings struct {
	UserID   string                        `json:"id"`
	DeviceID string                        `json:"deviceId"`
	Settings []FloActivityUserAlertSetting `json:"settings"`
}

type FloActivityUserAlertSetting struct {
	AlarmID      string `json:"alarmId"`
	SystemMode   string `json:"systemMode"`
	SmsEnabled   bool   `json:"smsEnabled"`
	EmailEnabled bool   `json:"emailEnabled"`
	PushEnabled  bool   `json:"pushEnabled"`
	CallEnabled  bool   `json:"callEnabled"`
	IsMuted      bool   `json:"isMuted"`
}

type FloAlarm struct {
	ID       int32  `json:"id"`
	Severity string `json:"severity"`
}

type BaseDevice struct {
	ID         string `json:"id"`
	MacAddress string `json:"macAddress"`
}

type FloExternalEntity struct {
	Vendor string      `json:"vendor"`
	Type   string      `json:"type"`
	ID     string      `json:"id"`
	Entity interface{} `json:"entity,omitempty"`
}

type FloActivityEnvelope struct {
	Location *FloActivityLocation `json:"location,omitempty"`
	User     *FloActivityUser     `json:"user,omitempty"`
	External FloExternalEntity    `json:"external"`
}

func (fe FloActivityEnvelope) String() string {
	return tryToJson(fe)
}

func (fe *FloActivityEnvelope) ValidateExternal(vendor, typ, id string) bool {
	if fe == nil {
		return false
	}
	if vendor != "" && !strings.EqualFold(fe.External.Vendor, vendor) {
		return false
	}
	if typ != "" && !strings.EqualFold(fe.External.Type, typ) {
		return false
	}
	if id != "" && !strings.EqualFold(fe.External.ID, id) {
		return false
	}
	return true
}

type EventBridgeMessage struct {
	ID         string           `json:"id"`
	DetailType string           `json:"detail-type"`
	Source     string           `json:"source"`
	Time       string           `json:"time"`
	Detail     *json.RawMessage `json:"detail"`
}

type ErrorPayload struct {
	Type    string `json:"type,omitempty"`
	Message string `json:"message,omitempty"`
}
