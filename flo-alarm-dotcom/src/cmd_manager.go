package main

import (
	"fmt"
	"github.com/pkg/errors"
	"strings"
	"time"
)

type CmdManager interface {
	// Invoke method bridge IntentInvoker interface for automatic logic routing
	Invoke(ctx InvokeCtx) (interface{}, error)
	Execute(authHead, did string, exe *HgCmdArgReq) (*CmdPayload, error)
}

type cmdExecFunc func(authHead string, dev *Device, exe *HgCmdArgReq) (res *CmdPayload, err error)

func CreateCmdManager(log Log, val Validator, seq SeqGen, pgw FloAPI) CmdManager {
	cm := cmdMan{log, val, seq, pgw, nil}
	cm.cmdMap = map[string]cmdExecFunc{ // key format is: <device-type>|<hg-command-name>
		"flo_device_v2|action.devices.commands.OpenClose": cm.valveToggle, //current valve version, fast match
		"flo_device_v*|action.devices.commands.OpenClose": cm.valveToggle, //wildcard (slow) match for future valves
	}
	for k, fnc := range cm.cmdMap { //ensure we re-map all strategy functions again with normalized names
		cm.cmdMap[strings.ToLower(k)] = fnc
	}
	return &cm
}

type cmdMan struct {
	log    Log
	val    Validator
	seq    SeqGen
	pgw    FloAPI
	cmdMap map[string]cmdExecFunc //strategy map
}

func (cm *cmdMan) Invoke(ctx InvokeCtx) (interface{}, error) {
	start := time.Now()
	cm.log = ctx.Log()
	cm.log.PushScope("Invoke", fmt.Sprintf("u=%v", ctx.UserId()))
	defer cm.log.PopScope()

	if args, e := cm.commands(ctx); e != nil {
		return nil, e //already logged
	} else {
		var (
			res  = make([]*CmdPayload, 0)
			errs = make([]error, 0)
			out  *CmdPayload
		)
		for _, cmd := range args {
			for _, dev := range cmd.Devices {
				for _, exe := range cmd.Execution {
					var pay *CmdPayload //single thread exc for now
					if pay, e = cm.Execute(ctx.AuthHeader(), dev.Id, exe); pay != nil {
						res = append(res, pay)
					} else if e != nil {
						errs = append(errs, e) //log err too
					}
				}
			}
		}
		out, e = cm.collapse(res), wrapErrors(errs)
		cm.logInv(start, out, e)
		return out, e
	}
}

type inPayloadExecute struct {
	Commands []*HgCommandReq `json:"commands" validate:"min=1,max=16,required,dive"`
}

type HgCommandReq struct {
	Devices   []*HgDeviceReq `json:"devices" validate:"min=1,max=32,required,dive"`
	Execution []*HgCmdArgReq `json:"execution" validate:"min=1,max=8,required,dive"`
}

type HgCmdArgReq struct {
	Command string                 `json:"command" validate:"min=8,max=64,required,contains=."`
	Params  map[string]interface{} `json:"params,omitempty"`
}

// ParamsAs casts input params into a type ref, validator is optional
func (ar *HgCmdArgReq) ParamsAs(o interface{}, valid Validator) (e error) {
	if ar == nil {
		e = errors.New("HgCmdArgReq receiver is nil")
	} else if e = jsonMap(ar.Params, o); e == nil && valid != nil {
		e = valid.Struct(o)
	}
	return
}

func (ar *HgCmdArgReq) ShortCmd() string {
	if ar == nil || ar.Command == "" {
		return ""
	}
	names := strings.Split(ar.Command, ".")
	if len(names) > 0 {
		return names[len(names)-1] //short cmd
	} else {
		return ar.Command
	}
}

func (ar HgCmdArgReq) String() string {
	return fmt.Sprintf("%v->%v", ar.ShortCmd(), tryToJson(ar.Params))
}

func (cm *cmdMan) commands(ctx InvokeCtx) (cmdArr []*HgCommandReq, err error) {
	cm.log.PushScope("cmdArr")
	defer cm.log.PopScope()

	inErrs := make([]error, 0)
	for _, input := range ctx.Req().Inputs {
		if len(input.Payload) == 0 {
			continue
		}
		arg := inPayloadExecute{}
		if e := input.PayloadAs(&arg, cm.val); e != nil {
			inErrs = append(inErrs, e)
		} else {
			for _, c := range arg.Commands {
				cmdArr = append(cmdArr, c)
			}
		}
	}
	if len(inErrs) != 0 {
		var (
			e  = &HttpErr{400, fmt.Sprintf("Bad Request: %v", inErrs), nil}
			ll = IfLogLevel(len(cmdArr) == 0, LL_ERROR, LL_WARN)
		)
		if ll == LL_ERROR {
			err = e
		}
		cm.log.Log(ll, e.Error())
	}
	return
}

func (cm *cmdMan) collapse(res []*CmdPayload) *CmdPayload {
	var (
		agg = make(map[string][]*CmdResult) //status_errCode as key
		key = func(c *CmdResult) string {
			return fmt.Sprintf("%v|%v", c.Status, c.ErrorCode)
		}
	)
	for _, r := range res {
		for _, c := range r.Commands {
			k := key(c)
			if arr, found := agg[k]; found {
				agg[k] = append(arr, c)
			} else {
				agg[k] = []*CmdResult{c}
			}
		}
	}
	out := CmdPayload{}
	for _, arr := range agg {
		r := CmdResult{}
		for i, o := range arr {
			r.Ids = append(r.Ids, o.Ids...)
			if i == 0 {
				r.Status = o.Status
				r.States = o.States //no CP b/c all cmd will resp 202, result will be pushed via reminder
				r.ErrorCode = o.ErrorCode
				r.ErrorDebug = o.ErrorDebug
			}
		}
		out.Commands = append(out.Commands, &r)
	}
	return &out
}

func (cm *cmdMan) logInv(start time.Time, out *CmdPayload, e error) {
	var (
		good = make([]string, 0)
		bad  = make([]string, 0)
		ll   = LL_DEBUG
	)
	for _, c := range out.Commands {
		if c.ErrorCode == "" {
			good = append(good, c.Ids...)
		} else {
			bad = append(bad, c.Ids...)
		}
	}
	if e != nil {
		ll = IfLogLevel(len(good) == 0, LL_ERROR, LL_NOTICE)
	}
	cm.log.Log(ll, "Done. Took %v OK=%v Fail=%v | %v", time.Since(start), good, bad, e)
}

type CmdPayload struct {
	Commands []*CmdResult `json:"commands"`
}

type CmdResult struct {
	Ids    []string `json:"ids"`
	States HgStat   `json:"states,omitempty"` //optional

	Status     string `json:"status"` //SUCCESS, OFFLINE, EXCEPTIONS, ERROR
	ErrorCode  string `json:"errorCode,omitempty"`
	ErrorDebug string `json:"errorDebug,omitempty"`
}

// Execute always return res (formatted as err resp), even if err is present
func (cm *cmdMan) Execute(authHead, did string, exe *HgCmdArgReq) (res *CmdPayload, err error) {
	cm.log.PushScope("Exec", exe.ShortCmd(), fmt.Sprintf("did=%v", did))
	defer cm.log.PopScope()

	dc := deviceCriteria{Id: did, Jwt: authHead}
	if dev, e := cm.pgw.GetDevice(&dc); e != nil {
		err = e
	} else if dev == nil {
		err = CreateHgError("deviceNotFound", errors.Errorf("did=%v %v", did, exe))
	} else if excPlan := cm.matchStrategy(dev, exe); excPlan != nil {
		var (
			pn  = GetFunctionName(excPlan)
			arr = strings.Split(pn, ".")
		)
		if l := len(arr); l > 0 {
			pn = arr[l-1]
		}
		cm.log.PushScope(strings.Replace(pn, "-fm", "", 1))
		defer cm.log.PopScope()
		res, err = excPlan(authHead, dev, exe)
	} else {
		err = CreateHgError("functionNotSupported", errors.Errorf("%v %v %v", dev.DeviceType, did, exe))
	}
	if res == nil && err != nil { // incl pre-formatted res
		res = cm.buildRespPayload(did, err)
	}
	cm.logExc(exe, res, err)
	return
}

func (cm *cmdMan) buildRespPayload(did string, err error) *CmdPayload {
	cr := CmdResult{
		Ids:        []string{did},
		Status:     "ERROR",
		ErrorCode:  "hardError",
		ErrorDebug: err.Error(),
	}
	switch he := err.(type) {
	case *HttpErr:
		cr.ErrorCode = hgErrCode(he.Code)
		if he.Message != "" {
			cr.ErrorDebug = he.Message
		}
	case *HgError:
		cr.ErrorCode = he.ErrorCode
		if he.Debug != "" {
			cr.ErrorDebug = he.Debug
		}
	case *HgIntentError:
		if he.Payload != nil {
			cr.ErrorCode = he.Payload.ErrorCode
			if he.Payload.Debug != "" {
				cr.ErrorDebug = he.Payload.Debug
			}
		}
	case *HgDevicesError:
		if e, ok := he.Payload.Devices[did]; ok && e != nil {
			cr.ErrorCode = e.ErrorCode
			if e.Debug != "" {
				cr.ErrorDebug = e.Debug
			}
		}
	}
	return &CmdPayload{Commands: []*CmdResult{&cr}}
}

func (cm *cmdMan) matchStrategy(dev *Device, exe *HgCmdArgReq) cmdExecFunc {
	var (
		stg     = strings.ToLower(fmt.Sprintf("%v|%v", dev.DeviceType, exe.Command))
		excPlan cmdExecFunc
	)
	if excPlan, _ = cm.cmdMap[stg]; excPlan == nil { //slow wildcard matches if normalized match not found
		for key, curFunc := range cm.cmdMap {
			if arr := strings.SplitN(key, "|", 2); len(arr) == 2 {
				var (
					devType = arr[0]
					cmdName = arr[1]
				)
				if strings.EqualFold(cmdName, exe.Command) {
					if starIx := strings.Index(devType, "*"); starIx >= 0 { //wildcard match
						if starIx == 0 {
							excPlan = curFunc //general match, don't break, maybe there's a more specific match
						} else if starIx > 0 {
							partial := devType[:starIx]
							if strings.Index(strings.ToLower(dev.DeviceType), partial) == 0 {
								excPlan = curFunc
								break //partial match found, stop here at the first one found
							}
						}
					}
				}
			}
		}
	}
	return excPlan
}

func (cm *cmdMan) logExc(exe *HgCmdArgReq, pay *CmdPayload, e error) {
	var (
		ll   = LL_INFO
		note interface{}
	)
	if e != nil {
		ll = IfLogLevel(pay == nil, LL_ERROR, LL_WARN)
	}
	if pay != nil {
		note = pay
	} else {
		note = e
	}
	cm.log.Log(ll, "%v | %v", tryToJson(exe.Params), tryToJson(note))
}

/** strategy definitions **/

// valveToggle fits cmdExecFunc type shape
func (cm *cmdMan) valveToggle(authHead string, dev *Device, exe *HgCmdArgReq) (res *CmdPayload, err error) {
	var valTar *Valve
	if valTar, err = cm.buildValveArg(dev, exe); err != nil {
		return
	}
	if e := cm.pgw.SetDeviceValve(dev.Id, authHead, valTar); e != nil { //relay cmd to Flo API
		code := "hardError"
		if he, good := e.(*HttpErr); good && he != nil {
			code = hgErrCode(he.Code)
			err = CreateHgError(code, errors.Errorf("pgw.SetDeviceValve did=%v %v | %v", dev.Id, exe, he))
		} else {
			err = CreateHgError(code, errors.Errorf("pgw.SetDeviceValve did=%v %v", dev.Id, exe))
		}
	} else { //success!
		var (
			st  = CreateValveMapper(dev).ToHgStat(cm.seq)
			cmd = CmdResult{
				Ids:    []string{dev.Id},
				Status: st.GetStatus(),
				States: st,
			}
		)
		if cmd.Status == "" {
			cmd.Status = "SUCCESS"
		}
		res = &CmdPayload{
			Commands: []*CmdResult{&cmd},
		}
	}
	return
}

type HgParamOpenClose struct {
	OpenPct     float32 `json:"openPercent" validate:"gte=0,lte=100"`
	FollowToken string  `json:"followUpToken,omitempty" validate:"omitempty,min=1,max=128"`
}

const (
	SWS_TARGET_OPEN  = "open"
	SWS_TARGET_CLOSE = "closed"
)

func (cm *cmdMan) buildValveArg(dev *Device, exe *HgCmdArgReq) (valTar *Valve, err error) {
	valTar = &Valve{}
	if _, found := exe.Params["openPercent"]; !found {
		err = CreateHgError("valueOutOfRange", errors.Errorf("VTG did=%v %v (missing field)", dev.Id, exe))
	} else {
		ocPrm := HgParamOpenClose{}
		if e := exe.ParamsAs(&ocPrm, cm.val); e != nil {
			err = CreateHgError("valueOutOfRange", errors.Errorf("VTG did=%v %v", dev.Id, exe))
		} else if ocPrm.OpenPct == 100 {
			valTar.Target = SWS_TARGET_OPEN
		} else if ocPrm.OpenPct == 0 {
			valTar.Target = SWS_TARGET_CLOSE
		} else { //discrete operations only, throw as err
			err = CreateHgError("percentOutOfRange", errors.Errorf("VTG did=%v %v", dev.Id, exe))
		}
	}
	if err != nil {
		return nil, err
	}
	if dev.Valve != nil {
		alreadyErr := func(cmp string) *HgError {
			switch valTar.Target {
			case "": //do nothing
			case SWS_TARGET_CLOSE:
				return CreateHgError("alreadyClosed", errors.Errorf("did=%v %v is already %v", dev.Id, cmp, valTar.Target))
			case SWS_TARGET_OPEN:
				return CreateHgError("alreadyOpen", errors.Errorf("did=%v %v is already %v", dev.Id, cmp, valTar.Target))
			}
			return nil
		}
		if noTarget, noLastKnown := dev.Valve.Target == "", dev.Valve.LastKnown == ""; !noLastKnown {
			if synced := strings.EqualFold(dev.Valve.LastKnown, dev.Valve.Target); synced || noTarget {
				if strings.EqualFold(valTar.Target, dev.Valve.LastKnown) { //already in requested state
					err = alreadyErr("lastKnown")
				}
			} else if !noTarget && strings.EqualFold(valTar.Target, dev.Valve.Target) { //duplicate target
				err = alreadyErr("target")
			}
		}
	}
	if err != nil {
		valTar = nil
	}
	return valTar, err
}
