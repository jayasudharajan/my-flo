package main

import (
	"encoding/json"
	"fmt"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/pkg/errors"
)

type EntityActivity struct {
	Id     string                 `json:"id"`
	Date   string                 `json:"date"`
	Type   string                 `json:"type"`
	Action string                 `json:"action"`
	Item   map[string]interface{} `json:"item"`
}

type EntityActivityKafkaConfig struct {
	KafkaConnection KafkaConnection
	GroupId         string
	Topic           string
}

type entityActivityHandler struct {
	logger Log
	kafSub KafkaSubscription
	kafCfg *EntityActivityKafkaConfig
	state  int32 // 0=closed, 1=open
	ntfFac EntityNotifyManagerFactory
}

// EntityActivityHandler notify when entity activity changes (device, location, account write/delete)
type EntityActivityHandler interface {
	Open()
	Close()
}

// CreateEntityActivityHandler logic is meant to be run as a singleton worker
func CreateEntityActivityHandler(
	logger Log,
	kafkaConfig *EntityActivityKafkaConfig,
	ntfFac EntityNotifyManagerFactory,
) EntityActivityHandler {

	eah := entityActivityHandler{
		logger: logger,
		kafSub: nil,
		kafCfg: kafkaConfig,
		ntfFac: ntfFac,
	}
	return &eah
}

func (eah *entityActivityHandler) Open() {
	if eah == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&eah.state, 0, 1) {
		eah.logger.Notice("Open: begin")
		go RetryIfError(eah.subscribe, time.Second*10, eah.logger)
	} else {
		eah.logger.Warn("Open: already opened")
	}
}

func (eah *entityActivityHandler) subscribe() error {
	defer panicRecover(eah.logger, "subscribe: %p", eah)

	if atomic.LoadInt32(&eah.state) != 1 {
		return errors.New("subscribe: not opened")
	}

	sub, err := eah.kafCfg.KafkaConnection.Subscribe(eah.kafCfg.GroupId, []string{eah.kafCfg.Topic}, eah.consumeMessage)
	if err != nil {
		return fmt.Errorf("subscribe: failed - %v", err)
	}
	if eah.kafSub != nil {
		eah.kafSub.Close()
	}

	eah.kafSub = sub
	eah.logger.Notice("subscribe: OK!")
	return nil
}

func (eah *entityActivityHandler) Close() {
	if atomic.CompareAndSwapInt32(&eah.state, 1, 0) {
		eah.logger.Debug("Close: begin")
		if eah.kafSub != nil {
			eah.kafSub.Close()
			eah.kafSub = nil
		}
		eah.logger.Notice("Close: OK")
	} else {
		eah.logger.Warn("Close: already closed")
	}
}

func (eah *entityActivityHandler) canNotify(evt *EntityActivity) bool {
	if evt != nil && evt.Id != "" && evt.Type != "" && evt.Action != "" {
		if evt.Date != "" {
			if dt := tryParseTime(evt.Date); dt.Year() > 2000 {
				if time.Since(dt) > MAX_ENT_ACT_AGE {
					return false //event too old!
				}
			}
		}
		return true
	}
	return false
}

func (eah *entityActivityHandler) consumeMessage(m *kafka.Message) {
	defer panicRecover(eah.logger, "consumeMessage: %s", m.Key)

	var evt EntityActivity
	if e := json.Unmarshal(m.Value, &evt); e != nil {
		eah.logger.IfErrorF(e, "consumeMessage: deserializing %s", m.Value)
	} else if eah.canNotify(&evt) {
		if notifier := eah.ntfFac(); notifier != nil {
			notifier.OnEntityChange(&evt)
		}
	}
}
