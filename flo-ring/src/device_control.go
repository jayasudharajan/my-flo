package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/pkg/errors"

	"github.com/go-redis/redis"
)

type ValveStatePayload struct {
	Mode  string           `json:"mode"`
	Cause *ValveStateCause `json:"cause,omitempty"`
}

type DeviceControlRedisConfig struct {
	reqExpiration int
}

type DeviceControlAmazonConfig struct {
	ApiKey string
}

type DeviceControlConfig struct {
	setValveStateDeferral int
	redis                 *DeviceControlRedisConfig
	amazon                *DeviceControlAmazonConfig
}

type ValveStateContext struct {
	MessageId string `json:msgId`
	UserId    string `json:userId`
}

type deviceControl struct {
	logger      *Logger
	config      *DeviceControlConfig
	redis       *RedisConnection
	deviceState DeviceState
	entityStore EntityStore
	pubGw       PublicGateway
	remindKey   string
	keyDur      KeyPerDuration
}

const valveStateKeyFormat = "ring.request.{%s}.valve-state.%s"

var _deviceControlKeyDur = CreateKeyPerDuration(DUR_4_HRS) //static singleton

type DeviceControl interface {
	SetValveState(ctx context.Context, accessToken string, userId string, directive *DirectiveMessage) (*EventMessage, error)
	HandleValveClosed(ctx context.Context, deviceId string, eventTime time.Time) (*EventMessage, error)
	HandleValveOpen(ctx context.Context, deviceId string, eventTime time.Time) (*EventMessage, error)
	HandleValveBroken(ctx context.Context, deviceId string, eventTime time.Time) (*EventMessage, error)
	HandlePropertyChange(ctx context.Context, device BaseDevice, propertyName, cause string, eventTime time.Time) (*EventMessage, error)
	CheckReminders(ctx context.Context) (evt *EventMessage, err error)
}

func CreateDeviceControl(
	logger *Logger,
	config *DeviceControlConfig,
	redis *RedisConnection,
	deviceState DeviceState,
	entityStore EntityStore,
	pubGw PublicGateway) DeviceControl {

	log := logger.CloneAsChild("deviceControl")
	dc := deviceControl{
		log,
		config,
		redis,
		deviceState,
		entityStore,
		pubGw,
		"",
		_deviceControlKeyDur}
	dc.remindKey = dc.initReminderKey()
	return &dc
}

func (dc *deviceControl) initReminderKey() string {
	key := getEnvOrDefault("FLO_VALVE_REMINDER_KEY", "ring:valve:remind")
	key = AppendKeyBranch(key, _commitBranch, dc.logger.isDebug)
	return key
}

func (dc *deviceControl) SetValveState(ctx context.Context, accessToken string, userId string, directive *DirectiveMessage) (*EventMessage, error) {
	var v ValveStatePayload
	err := jsonMap(directive.Directive.Payload, &v)
	if err != nil {
		return nil, &ValidationErr{fmt.Sprintf("setValveState: error while decoding payload - %v", err)}
	}

	var target string
	switch strings.ToLower(v.Mode) {
	case "states.open":
		target = "open"
	case "states.closed":
		target = "closed"
	default:
		return nil, &ValidationErr{fmt.Sprintf("Invalid mode: %s.", v.Mode)}
	}

	valveTarget := &Valve{Target: target}
	if v.Cause != nil && (v.Cause.Source != nil || v.Cause.Type != "") {
		valveTarget.Meta = &ValveStateMeta{Cause: v.Cause}
	} else { //set default cause
		srcId := "Unknown"
		if directive.Directive.Header.CorrelationToken != "" {
			srcId = directive.Directive.Header.CorrelationToken
		}
		valveTarget.Meta = &ValveStateMeta{
			Cause: &ValveStateCause{
				Type:   "APP_INTERACTION",
				Source: &ValveStateSource{Id: srcId, Type: "ALEXA_APP"},
			}}
	}

	deviceId := directive.Directive.Endpoint.EndpointId
	vsctx := &ValveStateContext{
		MessageId: directive.Directive.Header.MessageId,
		UserId:    userId,
	}
	err = dc.storeValveStateContext(ctx, deviceId, target, vsctx)
	if err != nil {
		return nil, fmt.Errorf("setValveState: error while storing valve state context for device %s to redis - %v", deviceId, err)
	}

	err = dc.pubGw.SetDeviceValve(deviceId, accessToken, valveTarget)
	if err != nil {
		return nil, err
	}
	return directive.toDeferred(dc.config.setValveStateDeferral), nil
}

func (dc *deviceControl) HandleValveClosed(ctx context.Context, deviceId string, eventTime time.Time) (*EventMessage, error) {
	return dc.handleValveStateChange(ctx, deviceId, "closed", eventTime)
}

func (dc *deviceControl) HandleValveOpen(ctx context.Context, deviceId string, eventTime time.Time) (*EventMessage, error) {
	return dc.handleValveStateChange(ctx, deviceId, "open", eventTime)
}

func (dc *deviceControl) HandleValveBroken(ctx context.Context, deviceId string, eventTime time.Time) (*EventMessage, error) {
	// Sending "broken" as state here will force a ValveChangeReport.
	// TODO: In case we need to send a Response, we need to check both for "open" and "closed" states
	// to see if we can obtain the context of the directive that originated this change.
	// We will need to do the same if we add "inTransition".
	return dc.handleValveStateChange(ctx, deviceId, "broken", eventTime)
}

func (dc *deviceControl) getPropertySets(d *Device, match string, eventTime time.Time) (matches, results []*Property, err error) {
	propsArr := make([]*Property, 0, 6)
	if strings.EqualFold(getEnvOrDefault("FLO_ENABLE_SYSTEM_MODE", ""), "true") {
		propsArr = append(propsArr, dc.deviceState.GetSystemModeProperty(d))
	}
	propsArr = append(propsArr,
		dc.deviceState.GetValveStateProperty(d),
		dc.deviceState.GetConnectivityProperty(d),
		dc.deviceState.GetSignalStrengthProperty(d),
		dc.deviceState.GetSignalNetworkIdentifierProperty(d),
	)
	jwt := "Bearer " + getEnvOrExit("FLO_API_RING_SERVICE_ACCESS_TOKEN")
	if alerts, e := dc.deviceState.GetPendingAlertsProperty(d, jwt); e != nil {
		err = e
	} else {
		propsArr = append(propsArr, alerts)
	}
	results = make([]*Property, 0, len(propsArr)-1)
	matches = make([]*Property, 0, 1)
	for _, p := range propsArr {
		if p.Name == "" {
			continue
		} else if strings.EqualFold(p.Name, match) { //reset
			resetTime := true
			if strings.EqualFold("deviceAlertsDetectionState", match) {
				if alerts, ok := p.Value.([]*RingAlert); ok && len(alerts) > 0 {
					if ts := dc.alertLatestTimeSample(alerts); ts.Year() > 2000 {
						resetTime = false
						p.TimeOfSample = ts.Format(TIME_FMT_NO_MS)
						p.UncertaintyMs = 0
					}
				}
			}
			if resetTime {
				p.TimeOfSample = eventTime.UTC().Format(TIME_FMT_NO_MS)
				p.UncertaintyMs = int(time.Since(eventTime).Milliseconds())
			}
			matches = append(matches, p)
		} else {
			results = append(results, p)
		}
	}
	return
}

func (dc *deviceControl) alertLatestTimeSample(alerts []*RingAlert) time.Time {
	ts := time.Time{}
	for _, a := range alerts {
		if a != nil && a.Time.After(ts) {
			ts = a.Time.UTC()
		}
	}
	return ts
}

func (dc *deviceControl) HandlePropertyChange(ctx context.Context, device BaseDevice, propertyName, cause string, eventTime time.Time) (*EventMessage, error) {
	if propertyName == "" {
		return nil, fmt.Errorf("HandlePropertyChange: %v, %v, %v | propertyName is blank", device, propertyName, cause)
	}
	if mac := Str(device.MacAddress); mac != "" {
		if ok, _ := dc.entityStore.DeviceExists(ctx, "", mac); !ok {
			ll := IfLogLevel(dc.keyDur.Check("404:"+mac, DUR_4_HRS), LL_DEBUG, LL_TRACE)
			dc.logger.Log(ll, "HandlePropertyChange: skipping prop %v - %v for mac %s because MISSING_REGISTRATION", propertyName, cause, mac)
			return nil, nil //skip
		}
	} else if did := Str(device.Id); did != "" {
		if ok, _ := dc.entityStore.DeviceExists(ctx, did, ""); !ok {
			ll := IfLogLevel(dc.keyDur.Check("404:"+did, DUR_4_HRS), LL_DEBUG, LL_TRACE)
			dc.logger.Log(ll, "HandlePropertyChange: skipping prop %v - %v for did %s because MISSING_REGISTRATION", propertyName, cause, did)
			return nil, nil //skip
		}
	} else { //ignore event not associated to a device
		return nil, nil
	}

	var (
		criteria = deviceCriteria{Id: Str(device.Id), Mac: Str(device.MacAddress)}
		d, err   = dc.pubGw.GetDevice(&criteria)
	)
	if err != nil {
		return nil, fmt.Errorf("HandlePropertyChange: %v, %v, %v - %v", device, propertyName, cause, err)
	}
	if d.Valve != nil {
		if d.Valve.Meta != nil && d.Valve.Meta.Cause != nil && d.Valve.Meta.Cause.Type == "APP_INTERACTION" &&
			d.Valve.Meta.Cause.Source != nil && d.Valve.Meta.Cause.Source.Type == "ALEXA_APP" {
			dc.logger.Debug("HandlePropertyChange: %v, %v Suppression of ChangeReport since cause=%q & source=%q",
				device, propertyName, d.Valve.Meta.Cause.Type, d.Valve.Meta.Cause.Source.Type)
			return nil, nil
		}
		dc.deviceState.EnsureValveMeta(d.Valve.Meta)
	}

	var source = ""
	if cause == "" {
		cause = "PERIODIC_POLL"
	} else {
		cause, source = dc.deviceState.EnsureCauseSource(cause, source)
	}

	mainProps, ctxProps, e := dc.getPropertySets(d, propertyName, eventTime)
	if len(ctxProps) == 0 && len(mainProps) == 0 && e != nil {
		return nil, fmt.Errorf("HandlePropertyChange: %v, %v, %v - %v", device, propertyName, cause, e)
	}
	em := EventMessage{
		Event: Event{
			Header: Header{
				Namespace:      "Alexa",
				Name:           "ChangeReport",
				MessageId:      newUUID(),
				PayloadVersion: "3",
			},
			Endpoint: dc.buildEndpoint(d.Id, ""),
			Payload: &ChangeReportPayload{
				Change: ChangeReport{Cause: ChangeCause{Type: cause}, Properties: mainProps},
			},
		},
		Context: &Context{Properties: ctxProps}, // rest of the properties
	}
	if len(mainProps) == 0 {
		dc.logger.Warn("HandlePropertyChange: %v, %v - %v, %v | can't match propertyName", d.Id, propertyName, cause, eventTime)
	} else {
		for _, prop := range mainProps {
			if strings.EqualFold(prop.Name, "mode") {
				if prop.Cookie == nil {
					prop.Cookie = make(map[string]interface{})
				}
				prop.Cookie["source"] = source
			}
		}
		dc.logger.Debug("HandlePropertyChange: OK did=%v mac=%v, %v - %v", d.Id, d.MacAddress, propertyName, cause)
	}
	return &em, nil
}

func (dc *deviceControl) handleValveStateChange(ctx context.Context, deviceId string, state string, eventTime time.Time) (*EventMessage, error) {
	vsctx, err := dc.getValveStateContext(ctx, deviceId, state)
	if err != nil {
		dc.logger.Debug("handleValveStateChange: NO_CONTEXT did=%v set -> %v", deviceId, state)
		if err == redis.Nil {
			return dc.buildValveChangeReport(ctx, deviceId, eventTime), nil
		}
		return nil, fmt.Errorf("handleValveStateChange: error getting device valve state for device %s - %v", deviceId, err)
	} else {
		dc.logger.Debug("handleValveStateChange: msgId=%v did=%v set -> %v", vsctx.MessageId, deviceId, state)
	}

	vsk := dc.buildValveStateKey(deviceId, state)
	if _, err = dc.redis.Delete(ctx, vsk); err != nil {
		dc.logger.Warn("handleValveStateChange: error deleting valve state key %v for device %s - %v", vsk, deviceId, err)
	} else {
		dc.logger.Trace("handleValveStateChange: rm OK %v", vsk)
	}
	if d, err := dc.entityStore.GetDirective(ctx, vsctx.MessageId); err != nil {
		return nil, fmt.Errorf("handleValveStateChange: error getting directive for message id %s and device %s - %v", vsctx.MessageId, deviceId, err)
	} else if d == nil {
		return dc.buildValveChangeReport(ctx, deviceId, eventTime), nil
	} else {
		return dc.buildResponse(d, vsctx, state, eventTime), nil
	}
}

func (dc *deviceControl) buildResponse(d *DirectiveMessage, ctx *ValveStateContext, state string, eventTime time.Time) *EventMessage {
	return &EventMessage{
		Context: &Context{
			Properties: []*Property{{
				Namespace:     d.Directive.Header.Namespace,
				Name:          "mode",
				Instance:      d.Directive.Header.Instance,
				Value:         strings.ToUpper(state),
				TimeOfSample:  eventTime.Format(TIME_FMT_NO_MS),
				UncertaintyMs: 0,
			}},
		},
		Event: Event{
			Header: Header{
				Namespace:        "Alexa",
				Name:             "Response",
				MessageId:        ctx.MessageId,
				CorrelationToken: d.Directive.Header.CorrelationToken,
				PayloadVersion:   d.Directive.Header.PayloadVersion,
			},
			Endpoint: dc.buildEndpoint(d.Directive.Endpoint.EndpointId, ctx.UserId),
		},
	}
}

func (dc *deviceControl) buildValveChangeReport(ctx context.Context, deviceId string, eventTime time.Time) *EventMessage {
	if time.Since(eventTime) >= time.Hour {
		dc.logger.Trace("buildValveChangeReport: %s skip OLD_EVENT at %v", deviceId, eventTime)
		return nil
	}
	if evt, err := dc.HandlePropertyChange(ctx, BaseDevice{Id: &deviceId}, "mode", "UNKNOWN", eventTime); err == nil {
		return evt
	}
	return nil
}

func (dc *deviceControl) buildEndpoint(endpointId string, userId string) *Endpoint {
	return &Endpoint{
		Scope:      dc.buildScope(userId),
		EndpointId: endpointId,
	}
}

func (dc *deviceControl) buildScope(userId string) *Scope {
	return &Scope{
		Type:              "ApiKey",
		ApiKey:            dc.config.amazon.ApiKey,
		AccountIdentifier: userId,
	}
}

func (dc *deviceControl) storeValveStateContext(c context.Context, deviceId string, state string, ctx *ValveStateContext) error {
	buf, err := json.Marshal(&ctx)
	if err != nil {
		return err
	}
	k := dc.buildValveStateKey(deviceId, state)
	if _, err = dc.redis.Set(c, k, buf, dc.config.redis.reqExpiration); err == nil {
		err = dc.pushReminder(c, &ValveReminder{deviceId, state, ctx})
	}
	if err == nil {
		dc.logger.Debug("storeValveStateContext: OK for %v", k)
	}
	return err
}

type ValveReminder struct {
	DeviceId string             `json:"deviceId"`
	State    string             `json:"state"`
	Ctx      *ValveStateContext `json:"ctx"`
}

func (v ValveReminder) String() string {
	return tryToJson(v)
}

func (dc *deviceControl) getReminderExpiration() time.Time {
	return time.Now().UTC().Truncate(time.Hour).Add(time.Hour)
}
func (dc *deviceControl) getReminderWriteKey() string {
	curHr := dc.getReminderExpiration()
	return fmt.Sprintf("%s:{%v}", dc.remindKey, curHr.Unix()) //current hr ends
}
func (dc *deviceControl) getReminderReadKeys() []string {
	curHr := dc.getReminderExpiration()
	return []string{
		fmt.Sprintf("%s:{%v}", dc.remindKey, curHr.Unix()),                 //current hr ends (priority)
		fmt.Sprintf("%s:{%v}", dc.remindKey, curHr.Add(-time.Hour).Unix()), //previous hr ends
	}
}

func (dc *deviceControl) pushReminder(ctx context.Context, vr *ValveReminder) (err error) {
	var buf []byte
	if buf, err = json.Marshal(vr); err == nil {
		var (
			remindKey = dc.getReminderWriteKey()
			wait      = int64(dc.config.setValveStateDeferral)
			decay     = wait - 5 + time.Now().Unix() //when to remind: 2s past expected referral time
		)
		if err = dc.redis.ZAdd(ctx, remindKey, float64(decay), buf); err == nil { //push reminder
			dc.logger.Debug("pushReminder: OK %v -> %v", remindKey, vr)
			if dc.keyDur.Check(remindKey, time.Hour) { //set TTL once an hour
				dc.redis._client.ExpireAt(ctx, remindKey, dc.getReminderExpiration()) //ignore ttl set error
			}
		}
	}
	return
}

func (dc *deviceControl) popReminder(ctx context.Context, key string) (*ValveReminder, error) {
	var (
		now         = float64(time.Now().Unix())
		count int64 = 10 //fetch 10 oldest items up to expiration of now
	)
	if arr, e := dc.redis.ZRangeByScoreWithScores(ctx, key, nil, &now, &count, nil); e != nil {
		return nil, e
	} else if len(arr) > 0 {
		lastHR := now - time.Hour.Seconds()
		for _, z := range arr {
			if z.Member == nil {
				continue
			}

			cmd := dc.redis._client.ZRem(ctx, key, z.Member) //attempt delete per item
			if n, e := cmd.Result(); e != nil {
				if e != redis.Nil {
					return nil, e
				}
			} else if n > 0 && z.Score > lastHR { //if delete is success & it hasn't been more than 1hr
				if js := fmt.Sprint(z.Member); len(js) > 5 && js[0] == '{' {
					note := ValveReminder{}
					if e = json.Unmarshal([]byte(js), &note); e != nil {
						return nil, e
					} else {
						dc.logger.Debug("popReminder: key=%v found reminder %v", key, &note)
						return &note, e //return the single item here
					}
				}
			}
		}
	}
	return nil, nil //nothing is found
}

// if err is redis.nil, sleep will be smaller
func (dc *deviceControl) CheckReminders(ctx context.Context) (evt *EventMessage, err error) {
	keys := dc.getReminderReadKeys()
	for _, k := range keys {
		if vr, e := dc.popReminder(ctx, k); e != nil {
			if e == redis.Nil {
				err = e
			} else {
				return nil, errors.Wrapf(e, "CheckReminders: pop %s", k)
			}
		} else if vr != nil && vr.Ctx != nil && vr.Ctx.MessageId != "" { //got a valid 1
			if n, e := dc.redis.Delete(ctx, dc.buildValveStateKey(vr.DeviceId, vr.State)); e != nil { //attempt to rm async response
				if e == redis.Nil {
					err = e
				} else {
					return nil, errors.Wrapf(err, "CheckReminders: error deleting valve state from redis for device %s", vr.DeviceId)
				}
			} else if n > 0 { //rm of async response OK :. it was not processed
				if dir, e := dc.entityStore.GetDirective(ctx, vr.Ctx.MessageId); e != nil { //pull og request
					if e == redis.Nil {
						err = e
					} else {
						return nil, errors.Wrapf(e, "CheckReminders: %s getDirective: %v", k, vr.Ctx.MessageId)
					}
				} else if dir != nil && strings.EqualFold(dir.Directive.Header.MessageId, vr.Ctx.MessageId) {
					evt = dc.buildErrResp(vr, dir) //build async err resp & return it
					break
				} else {
					dc.logger.Debug("CheckReminders: directive not found for msgId=%v", vr.Ctx.MessageId)
				}
			}
		}
	}
	return
}

func (dc *deviceControl) buildErrResp(vr *ValveReminder, dir *DirectiveMessage) *EventMessage {
	evt := EventMessage{
		Event: Event{
			Header: Header{
				Namespace:        "Alexa",
				Name:             "ErrorResponse",
				MessageId:        dir.Directive.Header.MessageId,
				CorrelationToken: dir.Directive.Header.CorrelationToken,
				PayloadVersion:   "3",
			},
			Endpoint: dir.Directive.Endpoint,
			Payload: &ErrorPayload{
				Type:    "ENDPOINT_UNREACHABLE",
				Message: fmt.Sprintf("Unable to reach endpoint %s because it appears to be offline", dir.Directive.Endpoint.EndpointId),
			},
		},
	}
	if evt.Event.Endpoint == nil {
		evt.Event.Endpoint = &Endpoint{
			EndpointId: vr.DeviceId,
		}
	}
	evt.Event.Endpoint.Scope = &Scope{
		Type:              "ApiKey",
		ApiKey:            dc.config.amazon.ApiKey,
		AccountIdentifier: vr.Ctx.UserId,
	}
	return &evt
}

func (dc *deviceControl) getValveStateContext(c context.Context, deviceId string, state string) (*ValveStateContext, error) {
	var ctx ValveStateContext
	ctxStr, err := dc.redis.Get(c, dc.buildValveStateKey(deviceId, state))
	if err != nil {
		return nil, err
	}

	if err = json.Unmarshal([]byte(ctxStr), &ctx); err != nil {
		return nil, err
	}
	return &ctx, nil
}

func (dc *deviceControl) buildValveStateKey(deviceId string, state string) string {
	key := strings.ToLower(fmt.Sprintf(valveStateKeyFormat, deviceId, state))
	key = AppendKeyBranch(key, _commitBranch, dc.logger.isDebug)
	return key
}
