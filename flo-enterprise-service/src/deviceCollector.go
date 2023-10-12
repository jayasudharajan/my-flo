package main

import (
	"context"
	"encoding/json"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/pkg/errors"
)

type CollectorKafkaConfig struct {
	kafkaConnection *KafkaConnection
	groupId         string
	topic           string
}

type deviceCollector struct {
	log                       *Logger               //impl
	kafkaConfig               *CollectorKafkaConfig //impl
	kafkaSubscription         *KafkaSubscription    //impl
	isOpen                    int32
	syncService               SyncService               //interface
	entityActivityBroadcaster EntityActivityBroadcaster //interface
}

func CreateDeviceCollector(log *Logger, kafkaConfig *CollectorKafkaConfig, syncService SyncService, entityActivityBroadcaster EntityActivityBroadcaster) Resource {
	return &deviceCollector{
		log:                       log.CloneAsChild("deviceCollector"),
		kafkaConfig:               kafkaConfig,
		syncService:               syncService,
		entityActivityBroadcaster: entityActivityBroadcaster,
	}
}

// #region KafkaSubscription
func (dc *deviceCollector) subscribe() error {
	defer panicRecover(dc.log, "subscribe: %p", dc)

	if atomic.LoadInt32(&dc.isOpen) != 1 {
		return errors.New("subscribe: not opened")
	}

	subscription, err := dc.kafkaConfig.kafkaConnection.Subscribe(dc.kafkaConfig.groupId, []string{dc.kafkaConfig.topic}, dc.consumeTask)
	if err != nil {
		return errors.Wrapf(err, "subscribe: subscription to %s failed", dc.kafkaConfig.topic)
	}

	if dc.kafkaSubscription != nil {
		dc.kafkaSubscription.Close()
	}

	dc.kafkaSubscription = subscription
	dc.log.Info("subscribe: subscription to %s ok!", dc.kafkaConfig.topic)
	return nil
}

func (dc *deviceCollector) Open() {
	if atomic.CompareAndSwapInt32(&dc.isOpen, 0, 1) {
		dc.log.Debug("Open: begin")
		err := retryIfError(dc.subscribe, time.Second*5, 3, dc.log)
		if err != nil {
			dc.log.Error("Open: error subscribing to kafka topic - %v", err)
		}
	} else {
		dc.log.Warn("Open: already opened")
	}
}

func (dc *deviceCollector) Close() {
	if atomic.CompareAndSwapInt32(&dc.isOpen, 1, 0) {
		dc.log.Debug("Close: begin")
		if dc.kafkaSubscription != nil {
			dc.kafkaSubscription.Close()
			dc.kafkaSubscription = nil
		}
		dc.log.Info("Close: OK")
	} else {
		dc.log.Warn("Close: already closed")
	}
}

// #endregion

// This is the deviceCollector and it only cares about device events
func (dc *deviceCollector) consumeTask(ctx context.Context, m *kafka.Message) {

	msg := EntityActivityMessage{}
	err := json.Unmarshal(m.Value, &msg)
	if err != nil {
		dc.log.Error("consumeTask: %v %v", err.Error(), string(m.Value))
		return
	}

	// only device entities
	if !strings.EqualFold(msg.Type, "device") {
		dc.log.Info("consumeTask: Entity is not a device: %s", msg.Type)
		return
	}

	isEnterpriseAccount := OptionalBool{HasValue: false}
	if msg.Item.Location != (EntityActivityLocation{}) && msg.Item.Location.Account != (EntityActivityAccount{}) && len(msg.Item.Location.Account.Type) > 0 {
		isEnterpriseAccount = OptionalBool{HasValue: true, Value: strings.EqualFold(msg.Item.Location.Account.Type, AT_Enterprise)}
	}

	// process device-created event (NOTE: syncService will check for whether enterprise device if necessary)
	if strings.EqualFold(msg.Action, "created") {
		dc.log.Info("consumeTask: sync paired device macAddress %s", msg.Item.MacAddress)
		dc.syncService.SyncDevice(ctx, msg.Item.MacAddress, isEnterpriseAccount)
	}

	// process lte event (should already have Account.Type specified as enterprise)
	if isEnterpriseAccount.Value && (strings.EqualFold(msg.Action, "created") || strings.EqualFold(msg.Action, "updated") || strings.EqualFold(msg.Action, "deleted")) {
		dc.log.Info("consumeTask: lte event for macAddress %s", msg.Item.MacAddress)
		rmsg := EntityActivityMessageRawItem{}
		err := json.Unmarshal(m.Value, &rmsg)
		if err != nil {
			dc.log.Error("consumeTask: %v %v", err.Error(), string(m.Value))
		} else {
			raw := rmsg.Item
			dc.entityActivityBroadcaster.broadcastRawItem(ctx, &msg, &raw)
		}
	}

	dc.log.Info("consumeTask: finished processing macAddress: %s", msg.Item.MacAddress)
}
