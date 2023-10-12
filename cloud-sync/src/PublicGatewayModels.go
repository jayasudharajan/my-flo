package main

import (
	"strings"
	"time"
)

type PublicGatewayUserModel struct {
	FirstName   string `json:"firstName,omitempty"`
	LastName    string `json:"lastName,omitempty"`
	PhoneMobile string `json:"phoneMobile,omitempty"`
	Locale      string `json:"locale,omitempty"`
	Email       string `json:"email,omitempty"`
}

type Account struct {
	Id   string `json:"id"`
	Type string `json:"type"`
}

type Location struct {
	Id      string           `json:"id"`
	Devices []LocationDevice `json:"devices"`
	Account Account          `json:"account"`
	Users   []User           `json:"users"`
}

type LocationDevice struct {
	Id          string `json:"id"`
	MacAddress  string `json:"macAddress"`
	IsConnected bool   `json:"isConnected"`
	FwVersion   string `json:"fwVersion"`
	DeviceModel string `json:"deviceModel"`
	DeviceType  string `json:"deviceType"`
}

type User struct {
	Id string `json:"id"`
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
