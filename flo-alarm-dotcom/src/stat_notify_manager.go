package main

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

type StatNotifyManager interface {
	OnAliveSignal(pulse *HeartBeatStatus)
	OnValveChange(state *ValveState)
	OnAlertPublish(event *Alert)

	ReportState(macOrDeviceId string) error
}

type statNotifyMan struct {
	statMan StatManager
	adcCred AdcTokenManager
	devRepo DeviceStore
	entRepo EntityStore
	htu     HttpUtil
	log     Log
	floApi  FloAPI
}

type StatNotifyManagerFactory func() StatNotifyManager

func CreateStatNotifyManager(
	statMan StatManager,
	adcCred AdcTokenManager,
	devRepo DeviceStore,
	entRepo EntityStore,
	htu HttpUtil,
	log Log,
	floApi FloAPI) StatNotifyManager {

	return &statNotifyMan{
		statMan, adcCred, devRepo, entRepo, htu, log, floApi}
}

func (sn *statNotifyMan) OnAliveSignal(pulse *HeartBeatStatus) {
	if pulse == nil || pulse.MacAddress == "" {
		return
	}
	sn.log.PushScope("Alive", pulse.MacAddress)
	defer sn.log.PopScope()
	sn.ReportState(pulse.MacAddress)
}

func (sn *statNotifyMan) OnValveChange(state *ValveState) {
	if state == nil || state.MacAddress == "" {
		return
	}
	sn.log.PushScope("Valve", state.MacAddress)
	defer sn.log.PopScope()
	sn.ReportState(state.MacAddress)
}

func (sn *statNotifyMan) OnAlertPublish(event *Alert) {
	if !sn.allowAlert(event) {
		return
	}
	if did := event.Device.GetId(); did != "" {
		sn.ReportState(did)
	} else if mac := event.Device.GetMac(); mac != "" {
		sn.ReportState(mac)
	}
}

func (sn *statNotifyMan) allowAlert(a *Alert) bool {
	if a != nil && a.Id != "" { //lightweight checks first
		//SEE: https://gpgdigital.atlassian.net/wiki/spaces/MAP/pages/1204617225/Flo-Moen+Alert+Notification+Settings+Mapping
		switch a.Alarm.Id {
		case 100, 101, 106, 107, 108: //SWD
		case 18, 33, 45, 46, 47, 48, 50, 51, 52, 53, 58, 63, 80, 81, 82, 83, 84: //SWS
			return true
		}
		found := false
		if _, found = swsLeakAlarmIds[a.Alarm.Id]; !found {
			if _, found = swsShutoffAlarmIds[a.Alarm.Id]; !found {
				if _, found = swdLeakAlarmIds[a.Alarm.Id]; !found {
					_, found = swdShutoffAlarmIds[a.Alarm.Id]
				}
			}
		}
		return found
	}
	return false
}

func (sn *statNotifyMan) floToken() string {
	if tk, e := sn.floApi.AdminToken(); e == nil {
		if tk.Token != "" {
			return tk.Token
		} else {
			sn.log.Warn("adminToken: empty fetch from -> %v", sn.floApi)
		}
	}
	return ""
}

func (sn *statNotifyMan) adcToken(usr *LinkedUser) (typ string, token string) {
	if usr == nil {
		return
	}
	var e error
	if usr.ClientId == "" && usr.UserId != "" { //re-fetch owner
		if usr, e = sn.entRepo.Get(usr.UserId, false); e != nil {
			sn.log.IfErrorF(e, "adcToken: owner get %q FAILED")
		}
	}
	if usr.ClientId != "" {
		var tk *OAuthResponse
		if tk, e = sn.adcCred.PushToken(usr.ClientId, false); e != nil {
			sn.log.IfErrorF(e, "adcToken: push token get cli=%q FAILED", usr.ClientId)
		} else if tk != nil && tk.AccessToken != "" {
			typ, token = tk.TokenType, tk.AccessToken
		}
	}
	return
}

func (sn *statNotifyMan) ReportState(macOrDid string) error {
	start := time.Now()
	sn.log.PushScope("Report", macOrDid)
	defer sn.log.PopScope()

	var (
		getDevice = sn.devRepo.GetByMac
		usr       *LinkedUser
		payload   *StatPayload
	)
	if !isValidMacAddress(macOrDid) {
		macOrDid = realDeviceId(macOrDid)
		getDevice = sn.devRepo.GetById
	}

	if device, e := getDevice(macOrDid, false); e != nil {
		return e
	} else if device == nil || device.Id == "" {
		return nil
	} else if floJwt := sn.floToken(); floJwt == "" {
		return sn.log.Warn("can't generate flo admin token")
	} else if usr, e = sn.entRepo.Get(device.UserId, false); e != nil {
		sn.log.IfErrorF(e, "entRepo.Get(%q)", device.UserId)
		return e
	} else {
		if adcType, adcJwt := sn.adcToken(usr); adcJwt != "" {
			if payload, e = sn.statMan.Check(floJwt, usr.Version, device.Id); e != nil {
				return e
			} else if payload == nil || len(payload.Devices) == 0 {
				return sn.log.Warn("payload is empty")
			} else if cfg := sn.adcCred.Env().Get(usr.ClientId); cfg == nil || cfg.Notify == "" {
				return sn.log.Error("adcEnv.Get(%q) -> empty notify", usr.ClientId)
			} else {
				var (
					token = strings.TrimSpace(fmt.Sprintf("%v %v", adcType, adcJwt))
					auth  = StringPairs{AUTH_HEADER, token}
					msg   = reportEnvelope{uuid.New().String(), usr.UserId, payload.ToReport()}
					resp  = make(map[string]interface{})
					genDt = time.Now()
				)
				if e = sn.htu.Do("POST", cfg.Notify, &msg, nil, &resp, auth); e != nil {
					sn.log.IfErrorF(e, "httpUtil.Do POST %v -> %v", cfg.Notify, &msg)
					return e
				} else {
					sn.log.Debug("ReportState: OK gen=%v post=%v | %v -> %v", genDt.Sub(start), time.Since(genDt), &msg, resp)
				}
			}
		}
	}
	return nil
}

type reportEnvelope struct {
	RequestId string      `json:"requestId"`
	UserId    string      `json:"agentUserId"`
	Payload   interface{} `json:"payload"`
}

func (re reportEnvelope) String() string {
	return tryToJson(&re)
}
