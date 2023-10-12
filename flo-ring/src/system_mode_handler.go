package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

type SystemModeHandler interface {
	Open()
	Close()
}

type systemModeHandler struct {
	logger  *Logger
	devCtrl DeviceControl
	kafConn *KafkaConnection
	kSub    *KafkaSubscription
	kTopic  string
	kGroup  string
	sns     RingQueue
	state   int32 // 0=closed, 1=open
	resChk  AllowResource
}

func CreateSystemModeHandler(
	log *Logger, devCtrl DeviceControl, kafConn *KafkaConnection, sns RingQueue, resChk AllowResource) SystemModeHandler {

	logger := log.CloneAsChild("systemModeHandler")
	sm := systemModeHandler{
		logger:  logger,
		devCtrl: devCtrl,
		sns:     sns,
		kafConn: kafConn,
		kTopic:  getEnvOrDefault("FLO_KAFKA_TOPIC_SYSTEM_MODE", "system-mode-v1"),
		kGroup:  getEnvOrExit("FLO_KAFKA_GROUP_ID"),
		resChk:  resChk,
	}
	logger.Notice("FLO_KAFKA_TOPIC_SYSTEM_MODE=%v", sm.kTopic)
	return &sm
}

func (smh *systemModeHandler) Open() {
	if smh == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&smh.state, 0, 1) {
		smh.logger.Notice("Open: begin")
		go RetryIfError(smh.subscribe, time.Second*10, smh.logger)
	} else {
		smh.logger.Warn("Open: already opened")
	}
}

func (smh *systemModeHandler) Close() {
	if atomic.CompareAndSwapInt32(&smh.state, 1, 0) {
		smh.logger.Debug("Close: begin")
		if smh.kSub != nil {
			smh.kSub.Close()
			smh.kSub = nil
		}
		smh.logger.Notice("Close: OK")
	} else {
		smh.logger.Warn("Close: already closed")
	}
}

func (smh *systemModeHandler) subscribe() error {
	defer panicRecover(smh.logger, "subscribe: %p", smh)

	if atomic.LoadInt32(&smh.state) != 1 {
		return errors.New("subscribe: not opened")
	}
	sub, err := smh.kafConn.Subscribe(smh.kGroup, []string{smh.kTopic}, smh.consumeMessage)
	if err != nil {
		return fmt.Errorf("subscribe: failed - %v", err)
	}

	if smh.kSub != nil {
		smh.kSub.Close()
	}
	smh.kSub = sub
	smh.logger.Notice("subscribe: OK!")
	return nil
}

type SystemModeMsg struct {
	Id           string `json:"id"`
	Name         string `json:"sn"`
	MacAddr      string `json:"did"`
	UnixTime     int64  `json:"ts"`
	CurrentMode  int32  `json:"st"`
	PreviousMode int32  `json:"pst"`
}

func (sm *SystemModeMsg) Time() time.Time {
	return time.Unix(sm.UnixTime, 0)
}

func (smh *systemModeHandler) consumeMessage(m *kafka.Message) {
	defer panicRecover(smh.logger, "consumeMessage: %s", m.Key)
	ctx, _ := tracing.InstaKafkaCtxExtractWithSpan(m, "")

	msg := SystemModeMsg{}
	if e := json.Unmarshal(m.Value, &msg); e != nil {
		smh.logger.IfWarnF(e, "consumeMessage: %v can't unmarshal %s", m.Key, m.Value)
	} else if !strings.EqualFold(msg.Name, "system-mode") {
		smh.logger.Trace("consumeMessage: BAD_TYPE_NAME %v", msg.Name)
	} else if !smh.resChk.Allow(msg.MacAddr) {
		return //debug ignore
	} else {
		switch msg.CurrentMode {
		case 2, 3, 5: //home, away, sleep. SEE: https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/778994089/System+Mode+Feature
			d := BaseDevice{MacAddress: &msg.MacAddr}
			if evt, e := smh.devCtrl.HandlePropertyChange(ctx, d, "systemMode", "APP_INTERACTION", msg.Time()); e != nil {
				smh.logger.IfWarnF(e, "consumeMessage: %v handlePropertyChange", msg)
			} else if e = smh.sns.Put(ctx, evt); e != nil {
				smh.logger.IfWarnF(e, "consumeMessage: %v sns PUT", evt)
			}
		default:
			smh.logger.Trace("consumeMessage: message.id %v (mac: %v) ignoring mode %v", m.Key, msg.MacAddr, msg.CurrentMode)
		}
	}
}
