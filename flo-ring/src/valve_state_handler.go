package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"

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
	KafkaConnection *KafkaConnection
	GroupId         string
	Topic           string
}

type ValveStateAmazonConfig struct {
	RingQueue RingQueue
}

type ValveStateProcessors struct {
	DeviceControl DeviceControl
}

type valveStateHandler struct {
	logger            *Logger
	kafkaSubscription *KafkaSubscription
	kafkaConfig       *ValveStateKafkaConfig
	amazonConfig      *ValveStateAmazonConfig
	processors        *ValveStateProcessors
	entityStore       EntityStore
	keyDur            KeyPerDuration
	state             int32 // 0=closed, 1=open
	errSleep          time.Duration
	resChk            AllowResource
	fakeBroken        BrokenValves
}

// notify when valve state changes
type ValveStateHandler interface {
	Open()
	Close()
}

var _valveStateHandlerKeyDur = CreateKeyPerDuration(DUR_4_HRS) //static singleton

// meant to be used as a singleton
func CreateValveStateHandler(
	logger *Logger,
	kafkaConfig *ValveStateKafkaConfig,
	amazonConfig *ValveStateAmazonConfig,
	processors *ValveStateProcessors,
	es EntityStore,
	resChk AllowResource,
	fakeBroken BrokenValves) ValveStateHandler {

	sleepMS, _ := strconv.ParseFloat(getEnvOrDefault("FLO_REMINDER_ERR_SLEEP_MS", ""), 64)
	if sleepMS <= 0 {
		sleepMS = 2000
	}
	vsh := valveStateHandler{
		logger:            logger.CloneAsChild("ValveStateHandler"),
		kafkaSubscription: nil,
		kafkaConfig:       kafkaConfig,
		amazonConfig:      amazonConfig,
		processors:        processors,
		entityStore:       es,
		errSleep:          time.Duration(sleepMS) * time.Millisecond,
		keyDur:            _valveStateHandlerKeyDur, // flush every 4hours
		resChk:            resChk,
		fakeBroken:        fakeBroken,
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
		go vsh.checkRemindersWorker()
	} else {
		vsh.logger.Warn("Open: already opened")
	}
}

func (vsh *valveStateHandler) subscribe() error {
	defer panicRecover(vsh.logger, "subscribe: %p", vsh)

	if atomic.LoadInt32(&vsh.state) != 1 {
		return errors.New("subscribe: not opened")
	}
	sub, err := vsh.kafkaConfig.KafkaConnection.Subscribe(vsh.kafkaConfig.GroupId, []string{vsh.kafkaConfig.Topic}, vsh.consumeMessage)
	if err != nil {
		return fmt.Errorf("subscribe: failed - %v", err)
	}

	if vsh.kafkaSubscription != nil {
		vsh.kafkaSubscription.Close()
	}
	vsh.kafkaSubscription = sub
	vsh.logger.Notice("subscribe: OK!")
	return nil
}

func (vsh *valveStateHandler) checkRemindersWorker() {
	for atomic.LoadInt32(&vsh.state) == 1 {
		vsh.checkReminder(context.Background())
	}
}

func (vsh *valveStateHandler) checkReminder(ctx context.Context) {
	defer panicRecover(vsh.logger, "checkReminder")

	if msg, err := vsh.processors.DeviceControl.CheckReminders(ctx); err != nil {
		if err == redis.Nil {
			time.Sleep(vsh.errSleep)
		} else {
			vsh.logger.IfErrorF(err, "checkReminder:")
			time.Sleep(vsh.errSleep * 2)
		}
	} else if msg == nil {
		time.Sleep(vsh.errSleep)
	} else if err = vsh.amazonConfig.RingQueue.Put(ctx, msg); err != nil {
		ep := "message #" + msg.Event.Header.MessageId
		if msg.Event.Endpoint != nil {
			ep = "device " + msg.Event.Endpoint.EndpointId
		}
		vsh.logger.Error("checkReminder: error putting event to queue for %s - %v", ep, err)
		time.Sleep(vsh.errSleep * 2)
	} else {
		vsh.logger.Debug("checkReminder: returning async error for %v", msg.Event.Header)
	}
}

func (vsh *valveStateHandler) Close() {
	if atomic.CompareAndSwapInt32(&vsh.state, 1, 0) {
		vsh.logger.Debug("Close: begin")
		if vsh.kafkaSubscription != nil {
			vsh.kafkaSubscription.Close()
			vsh.kafkaSubscription = nil
		}
		vsh.logger.Notice("Close: OK")
	} else {
		vsh.logger.Warn("Close: already closed")
	}
}

func (vsh *valveStateHandler) consumeMessage(m *kafka.Message) {
	defer panicRecover(vsh.logger, "consumeMessage: %s", m.Key)
	ctx, _ := tracing.InstaKafkaCtxExtractWithSpan(m, "")

	var vs ValveState
	if err := json.Unmarshal(m.Value, &vs); err != nil {
		vsh.logger.Error("consumeMessage: error while deserializing valve state message: %s - %v", m.Value, err)
		return
	} else if !vsh.resChk.Allow(vs.MacAddress) {
		return //debug rejection
	}
	deviceId, err := vsh.entityStore.GetDeviceIdByMac(ctx, vs.MacAddress)
	if err != nil {
		vsh.logger.Error("consumeMessage: error while getting device %s from store - %v", vs.MacAddress, err)
		return
	} else if deviceId == "" {
		ll := IfLogLevel(vsh.keyDur.Check("ring:"+vs.MacAddress, DUR_4_HRS), LL_DEBUG, LL_TRACE)
		vsh.logger.Log(ll, "consumeMessage: device %s is MISSING_REGISTRATION", vs.MacAddress)
		return
	}

	if vsh.fakeBroken.IsAny(deviceId, vs.MacAddress) {
		vs.State = 3 //force broken
	}

	var msg *EventMessage
	switch vs.State {
	case 0: // Closed
		msg, err = vsh.processors.DeviceControl.HandleValveClosed(ctx, deviceId, EpochToTime(vs.Timestamp))
	case 1: // Open
		msg, err = vsh.processors.DeviceControl.HandleValveOpen(ctx, deviceId, EpochToTime(vs.Timestamp))
	case 3: // Broken
		msg, err = vsh.processors.DeviceControl.HandleValveBroken(ctx, deviceId, EpochToTime(vs.Timestamp))
	default: // Dismiss
		vsh.logger.Debug("consumeMessage: skipping valve state %d for device %s", vs.State, vs.MacAddress)
		return
	}

	if err != nil {
		vsh.logger.Error("consumeMessage: error while processing valve state change for device %s - %v", deviceId, err)
		return
	} else if msg == nil {
		vsh.logger.Trace("consumeMessage: skipping valve state change for device %s", deviceId)
		return
	}
	if err = vsh.amazonConfig.RingQueue.Put(ctx, msg); err != nil {
		vsh.logger.Error("consumeMessage: error putting event to queue for device %s - %v", deviceId, err)
		return
	}
}
