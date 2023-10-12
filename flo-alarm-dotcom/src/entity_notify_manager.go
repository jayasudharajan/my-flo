package main

import (
	"errors"
	"fmt"
	"github.com/google/uuid"
	"strings"
	"time"
)

type EntityNotifyManager interface {
	OnEntityChange(ea *EntityActivity)

	SyncInvite(usr *LinkedUser) error
}

type entNotifyMan struct {
	adcCred AdcTokenManager
	devRepo DeviceStore
	entRepo EntityStore
	htu     HttpUtil
	log     Log
	floApi  FloAPI
	statFac StatNotifyManagerFactory
	keyDur  KeyPerDuration
}

type EntityNotifyManagerFactory func() EntityNotifyManager

var _entityNotifyKeyDur = CreateKeyPerDuration(MAX_ENT_ACT_AGE * 2) //static singleton

func CreateEntityNotifyManager(
	adcCred AdcTokenManager,
	devRepo DeviceStore,
	entRepo EntityStore,
	htu HttpUtil,
	log Log,
	floApi FloAPI,
	statFac StatNotifyManagerFactory) EntityNotifyManager {

	return &entNotifyMan{
		adcCred,
		devRepo,
		entRepo,
		htu,
		log,
		floApi,
		statFac,
		_entityNotifyKeyDur}
}

func (ent *entNotifyMan) OnEntityChange(ev *EntityActivity) {
	if ev == nil || ev.Id == "" || ev.Type == "" {
		return
	}
	var (
		start  = time.Now()
		lnkUsr entityChangeAction
	)
	switch typ := strings.ToLower(ev.Type); typ {
	case "user":
		lnkUsr = ent.userEvtFor
	case "device":
		lnkUsr = ent.deviceEvtFor
	case "location":
		lnkUsr = ent.locationEvtFor
	case "alert":
		lnkUsr = ent.alertEvtFor
	default:
		ent.log.Trace("ignored %v %v %v", ev.Type, ev.Action, ev.Id)
		return
	}
	if lnkUsr != nil {
		if usr, e := lnkUsr(ev); e != nil {
			ent.log.IfErrorF(e, "failed %v %v %v", ev.Type, ev.Action, ev.Id)
		} else if usr != nil {
			if e = ent.SyncInvite(usr); e != nil {
				ent.log.IfErrorF(e, "failed (sync) %v %v %v | usr=%v", ev.Type, ev.Action, ev.Id, usr.UserId)
			} else {
				ent.log.Debug("processed %v %v %v | usr=%v took=%v", ev.Type, ev.Action, ev.Id, usr.UserId, time.Since(start))
			}
		} else {
			ent.log.Trace("skipped %v %v %v", ev.Type, ev.Action, ev.Id)
		}
	}
}

const MAX_ENT_ACT_AGE = time.Minute * 30

func (ent *entNotifyMan) dupCheck(ev *EntityActivity) bool {
	k := fmt.Sprintf("%v%v:%v@%v", ev.Type, ev.Action, ev.Id, ev.Date)
	return ent.keyDur.Check(k, MAX_ENT_ACT_AGE)
}

type entityChangeAction func(ea *EntityActivity) (usr *LinkedUser, e error)

func (ent *entNotifyMan) adminToken() string {
	if tk, e := ent.floApi.AdminToken(); e != nil {
		ent.log.IfErrorF(e, "adminToken")
	} else if tk != nil && tk.Token != "" {
		return tk.Token
	}
	return ""
}

func (ent *entNotifyMan) userEvtFor(ea *EntityActivity) (usr *LinkedUser, e error) {
	switch act := strings.ToLower(ea.Action); act {
	case "updated", "deleted":
		if ent.dupCheck(ea) {
			if uid, found := ea.Item["id"]; found && uid != nil {
				if usrId, ok := uid.(string); ok && usrId != "" {
					if usr, e = ent.entRepo.Get(usrId, false); e == nil && usr != nil && act == "deleted" {
						if _, er := ent.entRepo.Delete(usrId); er != nil { //remove account link data, stop push to adc
							ent.log.IfWarnF(er, "userEvtFor..Delete %v | %v", usrId, ea.Id)
						} else { //TODO: send to ADC cloud when they support disconnect event
							usr = nil //don't do a sync invite
						}
					}
				}
			}
		}
	}
	return
}

func (ent *entNotifyMan) deviceEvtFor(ea *EntityActivity) (usr *LinkedUser, e error) {
	switch act := strings.ToLower(ea.Action); act {
	case "created":
		if ent.dupCheck(ea) {
			usr, e = ent.deviceCreatedFor(ea)
		}
	case "updated", "deleted":
		if ent.dupCheck(ea) {
			eaCp := *ea //preserve original ref of ea since id will change
			if usr, e = ent.deviceUpdatedFor(&eaCp); e == nil && usr != nil && act == "deleted" {
				er := ent.devRepo.DeleteById(eaCp.Id) //id has been swapped to deviceId
				ent.log.IfWarnF(er, "deviceEvtFor..DeleteById %v", eaCp.Id)
			}
		}
	}
	return
}

func (ent *entNotifyMan) deviceCreatedFor(ea *EntityActivity) (usr *LinkedUser, e error) {
	if jwt := ent.adminToken(); jwt != "" {
		var (
			cri    = deviceCriteria{ExpandLoc: true, Jwt: jwt}
			device *Device
		)
		if isValidMacAddress(ea.Id) {
			cri.Mac = ea.Id
		} else {
			cri.Id = ea.Id
		}
		if device, e = ent.floApi.GetDevice(&cri); device != nil && device.Location != nil {
			return ent.firstLinked(device.Location.Users)
		}
	}
	return
}

func (ent *entNotifyMan) deviceUpdatedFor(ea *EntityActivity) (usr *LinkedUser, e error) {
	var device *LinkedDevice
	if isValidMacAddress(ea.Id) {
		device, e = ent.devRepo.GetByMac(ea.Id, false)
	} else {
		device, e = ent.devRepo.GetById(ea.Id, false)
	}
	if device != nil && device.UserId != "" {
		ea.Id = device.Id //swap to device id
		usr = &LinkedUser{UserId: device.UserId}
	}
	return
}

func (ent *entNotifyMan) firstLinked(users []*User) (usr *LinkedUser, e error) {
	for _, u := range users {
		if u == nil || u.Id == "" {
			continue
		}
		if lnkUsr, er := ent.entRepo.Get(u.Id, false); er != nil {
			e = er
		} else if lnkUsr != nil { //found adc linked user, trigger a sync invite
			usr = lnkUsr
			e = nil
			break
		}
	}
	return
}

func (ent *entNotifyMan) locationEvtFor(ea *EntityActivity) (usr *LinkedUser, e error) {
	switch act := strings.ToLower(ea.Action); act {
	case "deleted": //"created", "updated",
		if raw, ok := ea.Item["users"]; ok && raw != nil {
			if ent.dupCheck(ea) {
				arr := make([]*User, 0)
				if e = jsonMap(raw, &arr); e == nil {
					return ent.firstLinked(arr)
				}
			}
		}
	}
	return
}

func (ent *entNotifyMan) alertEvtFor(ea *EntityActivity) (usr *LinkedUser, e error) {
	switch act := strings.ToLower(ea.Action); act {
	case "created", "updated": //"deleted"
		if ent.dupCheck(ea) {
			alr := Alert{}
			if e = jsonMap(ea.Item, &alr); e == nil && alr.Id != "" {
				if statNotify := ent.statFac(); statNotify != nil {
					statNotify.OnAlertPublish(&alr) //intentionally returning nothing, this method handle its own logging
				}
			}
		}
	}
	return
}

func (ent *entNotifyMan) adcToken(usr *LinkedUser) (typ string, token string) {
	if usr == nil {
		return
	}
	var e error
	if usr.ClientId != "" {
		var tk *OAuthResponse
		if tk, e = ent.adcCred.PushToken(usr.ClientId, false); e != nil {
			ent.log.IfErrorF(e, "adcToken: push token get cli=%q FAILED", usr.ClientId)
		} else if tk != nil && tk.AccessToken != "" {
			typ, token = tk.TokenType, tk.AccessToken
		}
	}
	return
}

type syncInviteEnvelope struct {
	RequestId   string `json:"requestId"`
	AgentUserId string `json:"agentUserId"`
}

func (si syncInviteEnvelope) String() string {
	return tryToJson(&si)
}

func (ent *entNotifyMan) SyncInvite(u *LinkedUser) error {
	if u == nil || u.UserId == "" {
		return errors.New("invalid user")
	} else if u.ClientId == "" { //load from repo
		if usr, e := ent.entRepo.Get(u.UserId, false); e != nil {
			return e
		} else if usr != nil && usr.UserId != "" {
			u = usr
		} else {
			return errors.New("user not found")
		}
	}

	if cfg := ent.adcCred.Env().Get(u.ClientId); cfg == nil || cfg.Notify == "" {
		return ent.log.Error("adcEnv.Get(%q) -> empty notify", u.ClientId)
	} else if adcType, adcJwt := ent.adcToken(u); adcJwt != "" {
		var (
			token = strings.TrimSpace(fmt.Sprintf("%v %v", adcType, adcJwt))
			auth  = StringPairs{AUTH_HEADER, token}
			msg   = syncInviteEnvelope{uuid.New().String(), u.UserId}
			resp  = make(map[string]interface{})
			genDt = time.Now()
		)
		if e := ent.htu.Do("POST", cfg.Notify, &msg, nil, &resp, auth); e != nil {
			var (
				ll   = LL_ERROR
				code = 0
			)
			if he, ok := e.(*HttpErr); ok && he != nil {
				code = he.Code
				if he.Code > 0 && he.Code < 500 {
					ll = IfLogLevel(he.Code < 400, LL_NOTICE, LL_WARN)
				}
			}
			ent.log.Log(ll, "httpUtil.Do POST %v %v | %v took=%v", cfg.Notify, &msg, code, time.Since(genDt))
			return e
		} else {
			took := time.Since(genDt)
			ent.log.Log(IfLogLevel(took > time.Second, LL_DEBUG, LL_TRACE), "SyncInvite: OK post=%v | %v -> %v", took, &msg, resp)
		}
	}
	return nil
}
