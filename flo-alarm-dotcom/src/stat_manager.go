package main

import (
	"context"
	"fmt"
	"golang.org/x/sync/semaphore"
	"strconv"
	"strings"
	"sync"
	"time"
)

// StatManager generate query intent response and notification payload
type StatManager interface {
	// Invoke method bridge IntentInvoker interface for automatic logic routing
	Invoke(ctx InvokeCtx) (interface{}, error)
	Check(authHead string, codeVersion int32, didOrMacs ...string) (*StatPayload, error)
}

var (
	_statSem  *semaphore.Weighted //global weighted limit for current device fetch
	_statBgCx context.Context
)

const envMaxDevFetch = "FLO_MAX_DEVICE_FETCH_SEM"

func init() {
	var (
		mx, _ = strconv.ParseInt(getEnvOrDefault(envMaxDevFetch, "4"), 10, 64)
		sw    = ClampInt64(mx, 1, 10)
	)
	_statSem = semaphore.NewWeighted(sw)
	_statBgCx = context.Background()
	_log.Notice("%v=%v", envMaxDevFetch, sw)
}

func CreateStatManager(log Log, val Validator, seq SeqGen, pgw FloAPI) StatManager {
	var usrVer int32 = 0 //never downgrade. using 0 as a conservative code default until everyone is upgraded for fetch
	if ver, _ := strconv.Atoi(getEnvOrDefault("FLO_USER_VERSION", "")); ver > 0 {
		usrVer = int32(ver)
	}
	return &statMan{log, val, seq, pgw, usrVer}
}

type statMan struct {
	log Log
	val Validator
	seq SeqGen
	pgw FloAPI

	usrVer int32
}

func (sm *statMan) Invoke(ctx InvokeCtx) (interface{}, error) {
	sm.log = ctx.Log() //swap instance logger
	sm.log.PushScope("Invoke", fmt.Sprintf("u=%v", ctx.UserId()))
	defer sm.log.PopScope()

	if items, e := sm.queries(ctx); e != nil { //already logged
		return nil, e
	} else {
		ids := make([]string, 0)
		for _, o := range items {
			ids = append(ids, o.Id)
		}
		return sm.Check(ctx.AuthHeader(), sm.usrVer, ids...) //NOTE: using version 0 to be conservative
	}
}

type inPayloadQuery struct {
	Devices []*HgDeviceReq `json:"devices" validate:"min=1,max=64,required,dive"`
}

type HgDeviceReq struct {
	Id         string          `json:"id" validate:"required,min=36,max=48"`
	CustomData *HgDevCustomDat `json:"customData,omitempty" validate:"omitempty,dive"`
}

func (sm *statMan) queries(ctx InvokeCtx) (queries []*HgDeviceReq, respErr error) {
	sm.log.PushScope("q")
	defer sm.log.PopScope()

	inErrs := make([]error, 0)
	for _, input := range ctx.Req().Inputs {
		if len(input.Payload) != 0 {
			dq := inPayloadQuery{}
			if e := input.PayloadAs(&dq, sm.val); e != nil {
				inErrs = append(inErrs, e)
			} else {
				for _, q := range dq.Devices {
					queries = append(queries, q)
				}
			}
		}
	}
	if len(inErrs) != 0 {
		var (
			e  = &HttpErr{400, fmt.Sprintf("Bad Request: %v", inErrs), nil}
			ll = IfLogLevel(len(queries) == 0, LL_ERROR, LL_WARN)
		)
		if ll == LL_ERROR {
			respErr = e
		}
		sm.log.Log(ll, e.Error())
	}
	return
}

type StatPayload struct { //for intent directive req
	Devices map[string]HgStat `json:"devices"`
}

func (sp *StatPayload) ToReport() *StatReport {
	if sp == nil {
		return nil
	}
	sr := StatReport{}
	sr.Devices.States = sp.Devices
	return &sr
}

type StatReport struct { //for notification push
	Devices struct {
		States map[string]HgStat `json:"states"`
	} `json:"devices"`
}

func (sm *statMan) Check(authHead string, codeVer int32, didOrMacs ...string) (*StatPayload, error) {
	sm.log.PushScope("Check")
	defer sm.log.PopScope()

	unqIds := sm.uniqueIds(didOrMacs)
	if stats, e := sm.stat(authHead, codeVer, unqIds...); e != nil {
		return nil, e
	} else {
		res := StatPayload{Devices: make(map[string]HgStat)}
		for _, s := range stats {
			if k := s.GetId(); k != "" {
				res.Devices[k] = s
			}
		}
		return &res, nil
	}
}

func (sm *statMan) uniqueIds(didOrMacs []string) []string {
	unqIds := make([]string, 0)
	unqMap := make(map[string]string)
	for _, s := range didOrMacs {
		unqMap[strings.ToLower(s)] = strings.TrimSpace(s)
	}
	for _, v := range unqMap {
		unqIds = append(unqIds, v)
	}
	return unqIds
}

func (sm *statMan) errCode(e error) string {
	code := "hardError" //by default
	switch et := e.(type) {
	case *HttpErr:
		switch et.Code {
		case 404:
			code = "unableToLocateDevice"
		case 401:
			code = "relinkRequired"
		case 403:
			code = "securityRestriction"
		case 502, 503:
			code = "transientError"
		}
	}
	return code
}

func (sm *statMan) stat(authHead string, codeVer int32, didOrMacs ...string) ([]HgStat, error) {
	var (
		res = make([]HgStat, 0)
		cx  = sm.batch(authHead, didOrMacs) //fetch in parallel
	)
	sm.log.PushScope("stat")
	defer sm.log.PopScope()

	for k, r := range cx.statRes {
		if r == nil || r.cmd == nil {
			sm.log.Warn("unableToLocateDevice %v", k)
			continue
		}
		if stats := sm.mkHgStat(k, codeVer, r); len(stats) > 0 {
			res = append(res, stats...)
		}
	}
	if len(res) == 0 {
		sm.log.Error("FOUND_NOTHING %v", didOrMacs)
		return nil, &HgError{Status: "ERROR", ErrorCode: "unableToLocateDevice"}
	}
	sm.statsLogResp(cx)
	return res, nil
}

func (sm *statMan) matchMapper(codeVer int32, mpr DeviceMapper, reqId string) bool {
	if codeVer >= 2 {
		return true
	} else if strings.EqualFold(mpr.Id(), reqId) {
		return true
	}
	return false
}

func (sm *statMan) mkHgStat(reqId string, codeVer int32, r *devStatGetRes) (res []HgStat) {
	var hg HgStat = &HgStatErr{Id: reqId, AdcSeqId: fmt.Sprint(sm.seq.Next())}
	if r == nil || r.dev == nil {
		if r.cmd.Id == "" { //can't do anything here...
			sm.log.Warn("found no device for mac=%v", r.cmd.Mac)
			return
		}
		if r.err != nil {
			sm.statsLogWarn(hg, sm.errCode(r.err), r.err)
		} else {
			sm.statsLogWarn(hg, "unableToLocateDevice", nil)
		}
	} else if r.err != nil {
		sm.statsLogWarn(hg, sm.errCode(r.err), r.err)
	}
	if r.dev != nil {
		dms := CreateDeviceMappers(r.dev, r.alr)
		if len(dms) == 0 {
			sm.statsLogWarn(hg, "functionNotSupported", nil)
			return []HgStat{hg}
		}
		for _, mpr := range dms {
			if sm.matchMapper(codeVer, mpr, reqId) {
				if stat := mpr.ToHgStat(sm.seq); stat != nil {
					res = append(res, stat)
				}
			}
		}
	}
	if len(res) == 0 && hg != nil {
		if strings.EqualFold(hg.GetStatus(), "ERROR") {
			sm.log.Warn("%v", hg)
		}
		res = []HgStat{hg}
	}
	return
}

func (sm *statMan) statsLogWarn(hg HgStat, errCode string, e error) {
	hg.SetErrCode(errCode, e)
	sm.log.Warn("%v | %v", hg, e)
}

func (sm *statMan) statsLogResp(cx *devStatCx) {
	var (
		ll   = IfLogLevel(cx.took > time.Second, LL_INFO, LL_DEBUG)
		rLen = len(cx.statRes)
		sb   = _loggerSbPool.Get()
	)
	defer _loggerSbPool.Put(sb)

	sb.WriteString("took=")
	sb.WriteString(cx.took.String())
	sb.WriteString(" | Found ")
	sb.WriteString(fmt.Sprint(len(cx.statRes)))
	sb.WriteString(" | ")
	for k, o := range cx.statRes {
		rLen--
		sb.WriteString(k)
		sb.WriteString(":")
		if o.err != nil || o.dev == nil {
			sb.WriteString("ER")
			ll = LL_NOTICE
		} else {
			sb.WriteString("OK")
		}
		if rLen > 0 {
			sb.WriteString(", ")
		}
	}
	sm.log.Log(ll, sb.String())
}

func (sm *statMan) batch(authHead string, didOrMacs []string) *devStatCx {
	var (
		st = time.Now()
		cx = devStatCx{
			wg:      new(sync.WaitGroup),
			mx:      new(sync.Mutex),
			statRes: make(map[string]*devStatGetRes),
		}
		prxMap = make(map[string]string)
	)
	for _, id := range didOrMacs {
		dc := deviceCriteria{Jwt: authHead}
		if idLen := len(id); idLen == 12 {
			dc.Mac = id
		} else if idLen == 36 {
			dc.Id = id
		} else {
			if realId := realDeviceId(id); len(realId) == 36 {
				prxMap[realId] = id //stash for result copy from batch fetch to reduce calls
			}
			continue
		}
		cx.wg.Add(1)
		go sm.fetch(&dc, &cx) //parallel fetches
	}
	cx.wg.Wait() //block until all fetches are done
	for realId, proxyId := range prxMap {
		if fetchRes, found := cx.statRes[realId]; found && fetchRes != nil {
			cx.statRes[proxyId] = fetchRes //pointer copy to proxy id to real result
		}
	}
	cx.took = time.Since(st)
	return &cx
}

func realDeviceId(did string) string {
	if idLen := len(did); idLen == 36 {
		return did
	} else if ix := strings.Index(did, ":"); ix >= 36 && idLen > 37 {
		return did[:ix]
	}
	return did
}

type devStatCx struct {
	wg      *sync.WaitGroup
	mx      *sync.Mutex
	statRes map[string]*devStatGetRes
	took    time.Duration
}

type devStatGetRes struct {
	cmd *deviceCriteria
	dev *Device
	alr []*Incident
	err error
}

func (sm *statMan) fetch(dc *deviceCriteria, cx *devStatCx) {
	defer cx.wg.Done()
	defer panicRecover(sm.log, "fetch: %v", dc)
	var (
		res = devStatGetRes{cmd: dc}
		k   = dc.Id
	)
	if k == "" {
		k = dc.Mac
	}
	_statSem.Acquire(_statBgCx, 1)
	defer _statSem.Release(1)
	if res.dev, res.err = sm.pgw.GetDevice(dc); res.err == nil && res.dev != nil {
		res.alr, res.err = sm.pgw.GetIncidents(res.dev.Id, dc.Jwt, true)
	}

	cx.mx.Lock()
	defer cx.mx.Unlock()
	cx.statRes[k] = &res
}
