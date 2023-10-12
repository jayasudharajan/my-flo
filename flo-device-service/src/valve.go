package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"sync"

	ot "github.com/opentracing/opentracing-go"
)

// ValveStateInternalPropertiesKey is the valve state internal properties (sent from the device) key
const ValveStateInternalPropertiesKey = "valve_state"
const valveKey = "valve"

const (
	VALVE_STATE_UNDEFINED  string = "undefined"
	VALVE_STATE_UNKNOWN    string = "unknown"
	VALVE_STATE_CLOSED     string = "closed"
	VALVE_STATE_OPEN       string = "open"
	VALVE_STATE_TRANSITION string = "inTransition"
	VALVE_STATE_BROKEN     string = "broken"
)

// PAYLOAD as of 08.20.19 {"id":"2e897689-5774-11e9-9928-26eadb2f2acd","sn":"valve-state","did":"587a6232d2f9","ts":1554449212004,"st":1,"pst":2}
type KafkaValveStateModel struct {
	Id            string `json:"id"`
	DeviceId      string `json:"did"`
	Timestamp     int64  `json:"ts"`
	State         int    `json:"st"`
	PreviousState int    `json:"pst"`
	StateName     string `json:"sn"`
}

func (o *KafkaValveStateModel) StateString() string {
	if o == nil {
		return valveIntToString(0)
	}

	return valveIntToString(o.State)
}

func (o *KafkaValveStateModel) PreviousStateString() string {
	if o == nil {
		return valveIntToString(0)
	}

	return valveIntToString(o.PreviousState)
}

func UnmarshalKafkaValveData(data []byte) *KafkaValveStateModel {
	if len(data) < 2 {
		return nil
	}

	rv := new(KafkaValveStateModel)
	err := json.Unmarshal(data, &rv)
	if err != nil {
		return nil
	}
	return rv
}

func ProcessValveKafkaMessage(ctx context.Context, payload []byte) {
	x := UnmarshalKafkaValveData(payload)
	if x == nil {
		return
	}
	SetLastKnownValveState(ctx, x.DeviceId, x.StateString())
}

func SetLastKnownValveState(ctx context.Context, deviceId string, valveState string) {
	if len(deviceId) != 12 || len(valveState) == 0 || !isValveStateValid(valveState) {
		logError("SetLastKnownValveState: Device: %v State %v. Database not updated.", deviceId, valveState)
		return
	}
	if !shouldSetValveState(valveState) {
		logDebug("SetLastKnownValveState: Ignoring valve state %v %v", deviceId, valveState)
		return
	}
	sp, ctx1 := ot.StartSpanFromContext(ctx, "SetLastKnownValveState")
	defer sp.Finish()

	// Clean the ID
	deviceId = strings.TrimSpace(strings.ToLower(deviceId))
	wg := new(sync.WaitGroup)

	// Set the value in Redis
	wg.Add(1)
	go func(c context.Context, w *sync.WaitGroup, d string, s string) {
		defer w.Done()
		ok, err := redisRepo.SetDeviceCachedData(c, d, map[string]interface{}{
			"valve.lastKnown": s,
		})
		if err != nil {
			logError("SetLastKnownValveState: REDIS: Device: %v Valve: %v Error: %v", d, s, err.Error())
		}

		if ok {
			logDebug("SetLastKnownValveState: REDIS: SET Device: %v Valve: %v", d, s)
		} else {
			logWarn("SetLastKnownValveState: REDIS: NOTSET Device: %v Valve: %v", d, s)
		}
	}(ctx1, wg, deviceId, valveState)

	// Set the value in Firestore
	wg.Add(1)
	go func(c context.Context, w *sync.WaitGroup, d string, s string) {
		defer w.Done()
		err := UpdateFirestore(c, d, map[string]interface{}{
			"deviceId": d,
			"valve": map[string]interface{}{
				"lastKnown": s,
			},
		})

		if err != nil {
			logError("SetLastKnownValveState: FW: Device: %v Valve: %v Error: %v", d, s, err.Error())
		} else {
			logDebug("SetLastKnownValveState: FW: SET Device: %v Valve: %v", d, s)
		}
	}(ctx1, wg, deviceId, valveState)

	// Set the value in Database
	wg.Add(1)
	go func(c context.Context, w *sync.WaitGroup, d string, s string) {
		defer w.Done()
		err := Dsh.SqlRepo.SetLastValve(c, d, s)

		if err != nil {
			logError("SetLastKnownValveState: PGDB: Device: %v Valve: %v Error: %v", d, s, err.Error())
		} else {
			logDebug("SetLastKnownValveState: PGDB: SET Device: %v Valve: %v", d, s)
		}
	}(ctx1, wg, deviceId, valveState)

	wg.Wait()
	// TODO: We should persist this data to PG, but we need to throttle writes
}

func valveIntToString(valve int) string {
	switch valve {
	case -1:
		return VALVE_STATE_UNKNOWN
	case 0:
		return VALVE_STATE_CLOSED
	case 1:
		return VALVE_STATE_OPEN
	case 2:
		return VALVE_STATE_TRANSITION
	case 3:
		return VALVE_STATE_BROKEN
	default:
		return VALVE_STATE_UNDEFINED
	}
}

func isValveStateValid(state string) bool {
	if len(state) == 0 {
		return false
	}

	return strings.EqualFold(state, VALVE_STATE_OPEN) ||
		strings.EqualFold(state, VALVE_STATE_CLOSED) ||
		strings.EqualFold(state, VALVE_STATE_TRANSITION) ||
		strings.EqualFold(state, VALVE_STATE_BROKEN)
}

func shouldSetValveState(state string) bool {
	if len(state) == 0 {
		return false
	}

	return strings.EqualFold(state, VALVE_STATE_OPEN) ||
		strings.EqualFold(state, VALVE_STATE_CLOSED) ||
		strings.EqualFold(state, VALVE_STATE_BROKEN)
}

func convertValveState(valveStateI interface{}) string {
	valveStateFloat, err := strconv.ParseFloat(fmt.Sprintf("%v", valveStateI), 64)
	if err != nil {
		logError("failed to convert system mode %v", valveStateI)
	}

	valveState := valveIntToString(int(valveStateFloat))
	return valveState
}

func parseFwPropertiesForValveState(fwPropertiesRaw map[string]interface{}) string {
	if len(fwPropertiesRaw) == 0 {
		return undefined
	}

	valveStateI, ok := fwPropertiesRaw[ValveStateInternalPropertiesKey]
	if ok {
		return convertValveState(valveStateI)
	}

	return undefined
}
