package main

import (
	"fmt"
	"strings"
	"time"
)

type User struct {
	Id        string `json:"id"`
	Email     string `json:"email"`
	FirstName string `json:"firstName"`
	LastName  string `json:"lastName"`
}

func (u User) String() string {
	return tryToJson(u)
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

func (d BaseDevice) String() string {
	return tryToJson(d)
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
	LastHeardFromTime *DateTime      `json:"lastHeardFromTime,omitempty"`
	Connectivity      *Connectivity  `json:"connectivity,omitempty"`
	Notifications     *Notifications `json:"notifications,omitempty"`
	Location          *Location      `json:"location,omitempty"`
	Valve             *Valve         `json:"valve,omitempty"`
	Mode              *SystemMode    `json:"systemMode,omitempty"`
	Battery           *Battery       `json:"battery,omitempty"`
}

type Battery struct {
	Level   int32  `json:"level"`
	Updated string `json:"updated"`
}

func (b *Battery) updatedDt() time.Time {
	if b != nil && b.Updated != "" {
		if dt := tryParseDate(b.Updated); dt.Year() > 2000 {
			return dt
		}
	}
	return time.Time{}
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
	Id       int32  `json:"id"`
	Severity string `json:"severity"`
	Count    int32  `json:"count"`
}

// Incident SEE: https://api-gw-dev.flocloud.co/docs/#/Incidents/get_api_v2_incidents
type Incident struct {
	Id         string     `json:"id"`
	Alarm      AlarmCount `json:"alarm"`
	Title      string     `json:"displayTitle"`
	Created    DateTime   `json:"createAt"`
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
	Id      string     `json:"id"`
	Status  string     `json:"status,omitempty"`
	Reason  string     `json:"reason,omitempty"`
	Updated DateTime   `json:"updateAt,omitempty"`
	Created DateTime   `json:"createAt,omitempty"`
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
	Id          int32  `json:"id"`
	Name        string `json:"name,omitempty"`
	Display     string `json:"displayName,omitempty"`
	Description string `json:"description,omitempty"`
	Severity    string `json:"severity"`
	IsInternal  bool   `json:"isInternal"`
}

func (a *Alarm) Clone() *Alarm {
	if a == nil {
		return nil
	}
	clone := *a
	return &clone
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

type JwtPayload struct {
	ClientId  string      `json:"client_id,omitempty"`
	UserId    string      `json:"user_id,omitempty"`
	User      *JwtUser    `json:"user,omitempty"`
	IssuedAt  int64       `json:"iat"`
	ExpiresAt int64       `json:"exp"`
	Version   interface{} `json:"v,omitempty"`
	TokenId   string      `json:"jti,omitempty"`
}

type JwtUser struct {
	UserId string `json:"user_id"`
	Email  string `json:"email"`
}

func (jp *JwtPayload) Expires() time.Time {
	return time.Unix(jp.ExpiresAt, 0).UTC()
}

func (jp *JwtPayload) Issued() time.Time {
	return time.Unix(jp.IssuedAt, 0).UTC()
}

func (jp *JwtPayload) VersionString() string {
	return fmt.Sprint(jp.Version)
}

func (jp *JwtPayload) FloUserId() string {
	if jp != nil {
		if jp.UserId != "" {
			return jp.UserId
		} else if jp.User != nil {
			return jp.User.UserId
		}
	}
	return ""
}
