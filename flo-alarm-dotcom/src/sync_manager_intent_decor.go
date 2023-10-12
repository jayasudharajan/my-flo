package main

import (
	"fmt"
	"strconv"
	"time"
)

// syncIntentDecor wraps SyncManager interface & trigger additional rules on Invoke(...)
type syncIntentDecor struct {
	base    IntentInvoker
	entRepo EntityStore
	devRepo DeviceStore
	log     Log
	onReg   []registerAction //on registration, trigger this
	usrVer  int32            //upgrade user data version to this
}

func CreateSyncIntentDecor(
	invoker IntentInvoker, entRepo EntityStore, devRepo DeviceStore, onReg ...registerAction) IntentInvoker {
	var userVer int32 = 2 //never downgrade default!
	if ver, _ := strconv.Atoi(getEnvOrDefault("FLO_USER_VERSION", "")); ver > 0 {
		userVer = int32(ver)
	}
	return &syncIntentDecor{invoker, entRepo, devRepo, nil, onReg, userVer}
}

func (sd *syncIntentDecor) Invoke(cx InvokeCtx) (interface{}, error) {
	sd.log = cx.Log()
	sd.log.PushScope("syncDecor")
	defer sd.log.PopScope()

	var clientId string
	if jwt := cx.Jwt(); jwt == nil || jwt.ClientId == "" {
		he := &HttpErr{401, "Unauthorized: token client is missing.", nil}
		return nil, CreateHgError("relinkRequired", he)
	} else {
		clientId = jwt.ClientId
	}
	res, e := sd.base.Invoke(cx) //base op

	if e == nil && res != nil { //discovery ok, save as linked alarm.com user
		var (
			usr     = LinkedUser{UserId: cx.UserId(), ClientId: clientId}
			devices []*HgDevice
		)
		if payload, ok := res.(*SyncPayload); ok && payload != nil {
			devices = payload.Devices
		}
		go sd.trigger(&registerCtx{cx, &usr, devices}) //side thread req so it doesn't block
	}
	return res, e //data as is
}

type registerCtx struct {
	invoke  InvokeCtx
	user    *LinkedUser
	devices []*HgDevice
}

func (rc registerCtx) String() string {
	reqId := ""
	if rc.invoke != nil {
		if req := rc.invoke.Req(); req != nil && req.RequestId != "" {
			reqId = req.RequestId
		}
	}
	return fmt.Sprintf("{reqId:%v,usr:%v}", reqId, rc.user)
}

type registerAction func(cx *registerCtx) (next bool, e error)

func (sd *syncIntentDecor) onRegisterActions() []registerAction {
	resp := []registerAction{ //construct chain of responsibility
		sd.register,
	}
	return append(resp, sd.onReg...) //append external triggers after our critical ones
}

func (sd *syncIntentDecor) trigger(cx *registerCtx) {
	defer panicRecover(sd.log, "syncIntentDecor.trigger: %v", cx)
	var (
		start     = time.Now()
		stepChain = sd.onRegisterActions()
		stepCount = len(stepChain)
		errCount  = 0
		okCount   = 0
	)
	for i, responsibility := range stepChain {
		var (
			stepName             = GetFunctionName(responsibility)
			ll                   = LL_DEBUG
			note     interface{} = "OK"
			next, e              = responsibility(cx)
		)
		if e != nil {
			errCount++
			note = e
			ll = IfLogLevel(next, LL_WARN, LL_ERROR)
		}
		sd.log.Log(ll, "syncIntentDecor.trigger: step=%v of %v %v | %v | %v", i, stepCount, stepName, note, cx)
		if next {
			okCount++
		} else {
			break
		}
	}
	ll := LL_INFO
	if errCount > 0 {
		ll = IfLogLevel(okCount == 0, LL_ERROR, LL_WARN)
	}
	sd.log.Log(ll, "syncIntentDecor.trigger: DONE took=%v steps=%v success=%v errors=%v | %v",
		time.Since(start), stepCount, okCount, errCount, cx)
}

// fits registerResponsibility function pointer
func (sd *syncIntentDecor) register(cx *registerCtx) (next bool, e error) {
	var (
		realIds = make(map[string]bool)
		lnkDevs = make([]*LinkedDevice, 0)
		didArr  = make([]string, 0)
	)
	for _, d := range cx.devices {
		realDid := realDeviceId(d.Id)
		if len(realDid) != 36 {
			continue //fake id, skip
		} else if _, found := realIds[realDid]; found {
			continue //skip repeat of real id
		}
		realIds[realDid] = true
		var (
			lnk = LinkedDevice{
				Id:     realDid,
				Mac:    d.CustomData.Mac,
				UserId: cx.user.UserId,
				LocId:  d.CustomData.LocationId,
			}
		)
		lnkDevs = append(lnkDevs, &lnk)
		didArr = append(didArr, realDid)
	}
	cx.user.Version = sd.usrVer //force version upgrade
	if _, e = sd.entRepo.Save(cx.user); e != nil {
		sd.log.IfErrorF(e, "register: entRepo.Save: %v", cx.user)
	} else if e = sd.devRepo.DeleteByUserId(cx.user.UserId); e != nil { //rm first to clr
		sd.log.IfErrorF(e, "register: devRepo.DeleteByUserId: %v", cx.user.UserId)
	} else if e = sd.devRepo.Save(lnkDevs...); e != nil { //replace new
		sd.log.IfErrorF(e, "register: devRepo.Save: %v", didArr)
	} else {
		next = true
		ll := IfLogLevel(next, LL_INFO, LL_DEBUG)
		sd.log.Log(ll, "register: OK | took=%v | %v | %v", time.Since(cx.user.Created), cx.user, didArr)
	}
	return
}
