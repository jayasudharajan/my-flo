package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/pkg/errors"
)

type ValveState struct {
	MacAddress    string `json:"did"`
	Timestamp     int64  `json:"ts"`
	State         int    `json:"st"`
	PreviousState int    `json:"pst"`
}

type ValveStateKafkaConfig struct {
	KafkaConnection KafkaConnection
	GroupId         string
	Topic           string
}

type valveStateHandler struct {
	logger      Log
	kafSub      KafkaSubscription
	kafCfg      *ValveStateKafkaConfig
	keyDur      KeyPerDuration
	state       int32 // 0=closed, 1=open
	errSleep    time.Duration
	newNotifier StatNotifyManagerFactory
}

// ValveStateHandler notify when valve state changes
type ValveStateHandler interface {
	Open()
	Close()
}

var _valveStateHandlerKeyDur = CreateKeyPerDuration(time.Minute * 15) //static singleton

// CreateValveStateHandler is meant to be used as a singleton
func CreateValveStateHandler(
	logger Log,
	kafkaConfig *ValveStateKafkaConfig,
	newNotifier StatNotifyManagerFactory) ValveStateHandler {

	sleepMS, _ := strconv.ParseFloat(getEnvOrDefault("FLO_REMINDER_ERR_SLEEP_MS", "2000"), 64)
	vsh := valveStateHandler{
		logger:      logger,
		kafSub:      nil,
		kafCfg:      kafkaConfig,
		errSleep:    time.Duration(ClampInt64(int64(sleepMS), 500, 5000)) * time.Millisecond,
		keyDur:      _valveStateHandlerKeyDur, // flush every 4hours
		newNotifier: newNotifier,
	}
	return &vsh
}

func (vsh *valveStateHandler) Open() {
	if vsh == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&vsh.state, 0, 1) {
		vsh.logger.Notice("Open: begin")
		go RetryIfError(vsh.subscribe, time.Second*10, vsh.logger)
	} else {
		vsh.logger.Warn("Open: already opened")
	}
}

func (vsh *valveStateHandler) subscribe() error {
	defer panicRecover(vsh.logger, "subscribe: %p", vsh)

	if atomic.LoadInt32(&vsh.state) != 1 {
		return errors.New("subscribe: not opened")
	}
	sub, err := vsh.kafCfg.KafkaConnection.Subscribe(vsh.kafCfg.GroupId, []string{vsh.kafCfg.Topic}, vsh.consumeMessage)
	if err != nil {
		return fmt.Errorf("subscribe: failed - %v", err)
	}

	if vsh.kafSub != nil {
		vsh.kafSub.Close()
	}
	vsh.kafSub = sub
	vsh.logger.Notice("subscribe: OK!")
	return nil
}

func (vsh *valveStateHandler) Close() {
	if atomic.CompareAndSwapInt32(&vsh.state, 1, 0) {
		vsh.logger.Debug("Close: begin")
		if vsh.kafSub != nil {
			vsh.kafSub.Close()
			vsh.kafSub = nil
		}
		vsh.logger.Notice("Close: OK")
	} else {
		vsh.logger.Warn("Close: already closed")
	}
}

func (vsh *valveStateHandler) consumeMessage(m *kafka.Message) {
	if !validKafkaMacKey(m) {
		return
	}
	defer panicRecover(vsh.logger, "consumeMessage: %s", m.Key)
	var vs ValveState
	if err := json.Unmarshal(m.Value, &vs); err != nil {
		vsh.logger.Error("consumeMessage: error while deserializing valve state message: %s - %v", m.Value, err)
		return
	} else if dt := time.Unix(vs.Timestamp/1000, 0); time.Since(dt) > time.Minute { //ignore things in the past
		return
	}

	var state string
	switch vs.State {
	case 0: // Closed
		state = "closed"
	case 1: // Open
		state = "open"
	case 3: // Broken
		state = "broken"
	default: // Dismiss
		ll := IfLogLevel(vs.State == 2, LL_TRACE, LL_DEBUG) //2 == in transition
		vsh.logger.Log(ll, "consumeMessage: skipping valve state %d for device %s", vs.State, vs.MacAddress)
		return
	}
	key := fmt.Sprintf("vs:%v:%v", strings.ToLower(vs.MacAddress), vs.State)
	if ok := vsh.keyDur.Check(key, time.Second*5); ok {
		vsh.logger.Trace("consumeMessage: OK %v | %s", state, vs.MacAddress)
		notify := vsh.newNotifier()
		notify.OnValveChange(&vs)
	} else {
		vsh.logger.Trace("consumeMessage: DUPLICATE valve state %v for %s", state, vs.MacAddress)
	}
}
