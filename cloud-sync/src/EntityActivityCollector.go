package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis/v8"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/pkg/errors"
)

type EntityActivityCollector interface {
	Open(ctx context.Context)
	Close(ctx context.Context)
	Process(ctx context.Context, msg *EntityActivityMessage) (*EventBridgeClientPublishInput, error)
	Ping(ctx context.Context) error
}

type entityActivityCollector struct {
	log               *Logger
	kafkaConfig       *kafkaConfig
	eventBridge       AWSEventBridgeClient
	kafkaSubscription *KafkaSubscription
	isOpen            int32
	redis             *RedisConnection
	moenAuthSvc       MoenAuthService
	publicGateway     PublicGateway
	useLinkedLoc      bool
	deDuper           KeyPerDuration
}

type kafkaConfig struct {
	kafkaConnection *KafkaConnection
	groupId         string
	topic           string
}

type entityActivityCollectorConfig struct {
	log           *Logger
	kafkaConfig   *kafkaConfig
	redis         *RedisConnection
	eventbridge   AWSEventBridgeClient
	moenAuthSvc   MoenAuthService
	publicGateway PublicGateway
}

func NewEntityActivityCollector(c *entityActivityCollectorConfig) EntityActivityCollector {
	var (
		minFlush = time.Minute * 2
		maxFlush = time.Hour * 2
		flush    = time.Minute * 5
	)
	if fsh, e := time.ParseDuration(getEnvOrDefault("FLO_ENTITY_ACTIVITY_DEDUPE_FLUSH", "")); e == nil {
		if fsh > maxFlush {
			flush = maxFlush
		} else if fsh < minFlush {
			flush = minFlush
		} else {
			flush = fsh
		}
	}
	return &entityActivityCollector{
		log:           c.log.CloneAsChild("EntityActivityCollector"),
		kafkaConfig:   c.kafkaConfig,
		redis:         c.redis,
		eventBridge:   c.eventbridge,
		moenAuthSvc:   c.moenAuthSvc,
		publicGateway: c.publicGateway,
		useLinkedLoc:  strings.EqualFold("true", getEnvOrDefault("FLO_USE_LINKED_LOCATION", "")),
		deDuper:       CreateKeyPerDuration(flush),
	}
}

func (eac *entityActivityCollector) Ping(ctx context.Context) error {
	if atomic.LoadInt32(&eac.isOpen) == 0 {
		return eac.log.Warn("Ping: state==0 (closed)")
	} else if eac.kafkaConfig == nil || eac.kafkaConfig.kafkaConnection == nil {
		return eac.log.Warn("Ping: kafkaConfig or connection is nil")
	} else if e := eac.kafkaConfig.kafkaConnection.Producer.GetFatalError(); e != nil {
		return eac.log.IfErrorF(e, "Ping: producer")
	} else if eac.kafkaSubscription == nil || eac.kafkaSubscription.Consumer == nil {
		return eac.log.Warn("Ping: subscriber is nil")
	} else if eac.kafkaConfig.topic == "" {
		return eac.log.Warn("Ping: kafka topic is blank")
	} else if _, e = eac.kafkaSubscription.Consumer.GetMetadata(&eac.kafkaConfig.topic, false, 3000); e != nil {
		return eac.log.IfErrorF(e, "Ping: consumer")
	} else {
		return nil
	}
}

func (eac *entityActivityCollector) consumeTask(ctx context.Context, m *kafka.Message) {
	defer panicRecover(eac.log, "consumeTask: %v", m)
	if hash, e := mh3(fmt.Sprintf("%s|%s", m.Key, m.Value)); e == nil && hash != "" {
		if !eac.deDuper.Check(hash, time.Second*30) {
			eac.log.Debug("consumeTask: duplicate rejection %s", m.Value)
			return
		}
	}

	msg := EntityActivityMessage{}
	if err := json.Unmarshal(m.Value, &msg); err != nil {
		eac.log.IfErrorF(err, "consumeTask: %s", m.Value)
		return
	}
	eac.Process(ctx, &msg)
}

// Process exposed for easy integration test
func (eac *entityActivityCollector) Process(ctx context.Context, msg *EntityActivityMessage) (*EventBridgeClientPublishInput, error) {
	if msg == nil {
		return nil, nil
	}
	msg.NormalizeRequestID()
	eac.log.Trace("consumeTask: %v %v %v | req=%v", msg.Type, msg.Action, msg.Id, msg.RequestID)

	act := strings.ToLower(msg.Action)
	switch typ := strings.ToLower(msg.Type); typ {
	case EVENT_TYPE_ALERT:
		if eac.canNotifyAlert(ctx, msg) {
			return eac.publishToEventBridge(ctx, msg, nil)
		}
	case EVENT_TYPE_LOCATION:
		switch act {
		case EVENT_ACTION_LINKED: //not needed now, doing this for future compatibility
			if eac.canNotifyLocationLinked(ctx, msg) {
				return eac.publishToEventBridge(ctx, msg, nil)
			}
		case EVENT_ACTION_UNLINKED:
			return eac.publishToEventBridge(ctx, msg, nil) //send as is, data is already removed from dbs, can't check
		}
	case EVENT_TYPE_USER:
		switch act {
		case EVENT_ACTION_LINKED: //not needed now, doing this for future compatibility
			if eac.canNotifyUserLinked(ctx, msg) {
				return eac.publishToEventBridge(ctx, msg, nil) //send as is, data is already removed from dbs, can't check
			}
		case EVENT_ACTION_UNLINKED:
			return eac.publishToEventBridge(ctx, msg, nil) //send as is, data is already removed from dbs, can't check
		}
	case EVENT_TYPE_DEVICE:
		switch act {
		case "paired", "updated", EVENT_ACTION_CREATED:
			if eac.canNotifyDevice(ctx, msg) {
				return eac.publishToEventBridge(ctx, msg, nil)
			}
		case "unpaired", EVENT_ACTION_DELETED:
			if eac.canNotifyDevice(ctx, msg) {
				return eac.publishToEventBridge(ctx, msg, nil)
			}
		}
	case EVENT_TYPE_ALARM_SETTINGS:
		switch act {
		case EVENT_ACTION_UPDATED:
			if eac.canNotifyUserLinkedForUpdate(ctx, msg) {
				return eac.publishToEventBridge(ctx, msg, nil)
			}
		}
	}
	return nil, nil
}

func (eac *entityActivityCollector) canNotifyUserLinked(ctx context.Context, msg *EntityActivityMessage) bool {
	lnk := FloActivityEnvelope{}
	if e := json.Unmarshal(msg.Item, &lnk); e == nil && lnk.User != nil && lnk.User.ID != "" &&
		lnk.ValidateExternal("moen", "user", "") {
		var moenId string
		if moenId, e = eac.moenAuthSvc.GetSyncByFloUserId(ctx, lnk.User.ID); e == nil {
			return strings.EqualFold(moenId, lnk.External.ID)
		}
	}
	return false
}

func (eac *entityActivityCollector) canNotifyUserLinkedForUpdate(ctx context.Context, msg *EntityActivityMessage) bool {
	uas := FloEntity{}
	if e := json.Unmarshal(msg.Item, &uas); e == nil && uas.ID != "" {
		var moenId string
		if moenId, e = eac.moenAuthSvc.GetSyncByFloUserId(ctx, uas.ID); e == nil {
			return moenId != ""
		}
		return false
	}
	return false
}

func (eac *entityActivityCollector) canNotifyLocationLinked(ctx context.Context, msg *EntityActivityMessage) bool {
	lnk := FloActivityEnvelope{}
	if e := json.Unmarshal(msg.Item, &lnk); e == nil && lnk.Location != nil && lnk.Location.ID != "" &&
		lnk.ValidateExternal("moen", "location", "") {
		var o *SyncLoc
		if o, e = eac.moenAuthSvc.GetLinkedLocation(ctx, lnk.Location.ID); e == nil && o != nil {
			return strings.EqualFold(o.MoenId, lnk.External.ID)
		}
	}
	return false
}

func (eac *entityActivityCollector) canNotifyDevice(ctx context.Context, msg *EntityActivityMessage) bool {
	device := FloActivityDevice{}
	if e := json.Unmarshal(msg.Item, &device); e == nil && device.ID != "" {
		if device.Location != nil && device.Location.ID != "" {
			var loc *SyncLoc
			if loc, e = eac.moenAuthSvc.GetLinkedLocation(ctx, device.Location.ID); e == nil && loc != nil && loc.MoenId != "" {
				return true
			}
		} else {
			var (
				dev *Device
				loc *SyncLoc
			)
			if dev, e = eac.publicGateway.GetDevice(ctx, device.ID, ""); e == nil && dev.Location != nil && dev.Location.Id != "" {
				if loc, e = eac.moenAuthSvc.GetLinkedLocation(ctx, dev.Location.Id); e == nil && loc != nil && loc.MoenId != "" {
					return true
				}
			}
		}
	}
	return false
}

func (eac *entityActivityCollector) canNotifyAlert(ctx context.Context, msg *EntityActivityMessage) bool {
	alert := FloActivityAlert{}
	if err := json.Unmarshal(msg.Item, &alert); err == nil && alert.LocationId != "" {
		if eac.useLinkedLoc {
			var loc *SyncLoc
			if loc, err = eac.moenAuthSvc.GetLinkedLocation(ctx, alert.LocationId); err == nil && loc != nil && loc.MoenId != "" {
				return true
			}
		} else { //old slower method
			var (
				loc    *Location
				moenId string
			)
			if loc, err = eac.publicGateway.GetLocationById(ctx, alert.LocationId, msg.RequestID); err == nil && loc != nil && len(loc.Users) != 0 {
				for _, usr := range loc.Users {
					if moenId, err = eac.moenAuthSvc.GetSyncByFloUserId(ctx, usr.Id); err == nil && moenId != "" {
						return true
					}
				}
			}
		}
	}
	return false
}

func (eac *entityActivityCollector) canPublishToEventBridge(ctx context.Context, msg *EntityActivityMessage) bool {
	if len(msg.RequestID) > 0 {
		var (
			key    = fmt.Sprintf("mutex:cloudsync:event:request:%v", msg.RequestID)
			source string
			err    error
		)
		if source, err = eac.redis.Get(ctx, key); err != nil && err != redis.Nil {
			eac.log.IfErrorF(err, "canPublishToEventBridge: error retrieving request lock %v", msg.RequestID)
			return false
		}
		if len(source) > 0 {
			eac.log.Trace("canPublishToEventBridge: ignoring event originating from source %v %v", source, msg.RequestID)
			return false
		}
	}
	return true
}

func (eac *entityActivityCollector) buildInput(msg *EntityActivityMessage, payload interface{}) (*EventBridgeClientPublishInput, error) {
	evi := EventBridgeClientPublishInput{
		MessageType:   msg.Type,
		MessageAction: msg.Action,
		RequestID:     msg.RequestID,
		Payload:       &msg.Item,
	}
	if payload != nil {
		switch o := payload.(type) {
		case *json.RawMessage:
			evi.Payload = o
		case json.RawMessage:
			evi.Payload = &o
		case []byte:
			var buf json.RawMessage = o
			evi.Payload = &buf
		case string:
			var buf json.RawMessage = []byte(o)
			evi.Payload = &buf
		default:
			if buf, e := json.Marshal(payload); e != nil {
				return nil, e
			} else if len(buf) > 8 {
				var raw json.RawMessage = buf
				evi.Payload = &raw
			}
		}
	}
	return &evi, nil
}

// payload is optional, if not nil, it will be used as event bridge message when sent (or msg.Item will be used)
func (eac *entityActivityCollector) publishToEventBridge(ctx context.Context, msg *EntityActivityMessage, payload interface{}) (*EventBridgeClientPublishInput, error) {
	if msg == nil {
		return nil, &HttpErr{400, "nil input", false, nil}
	} else if !eac.canPublishToEventBridge(ctx, msg) {
		return nil, &HttpErr{409, "blocked input: feedback loop", false, nil}
	}

	if evi, err := eac.buildInput(msg, payload); err != nil {
		return nil, eac.log.IfErrorF(err, "publishToEventBridge: error building input")
	} else if err = eac.eventBridge.Publish(ctx, evi); err != nil {
		return nil, eac.log.IfErrorF(err, "publishToEventBridge: error publishing")
	} else {
		eac.log.Debug("publishToEventBridge: OK  %v %v %v | req=%v | %s", msg.Type, msg.Action, msg.Id, msg.RequestID, evi.Payload)
		return evi, nil
	}
}

func (eac *entityActivityCollector) subscribe(ctx context.Context) error {
	defer panicRecover(eac.log, "subscribe: %p", eac)

	if atomic.LoadInt32(&eac.isOpen) != 1 {
		return errors.New("subscribe: not opened")
	}

	subscription, err := eac.kafkaConfig.kafkaConnection.Subscribe(
		eac.kafkaConfig.groupId, []string{eac.kafkaConfig.topic}, eac.consumeTask)
	if err != nil {
		err = errors.Wrapf(err, "subscribe: subscription to %s failed", eac.kafkaConfig.topic)
		eac.log.IfError(err)
		return err
	}

	if eac.kafkaSubscription != nil {
		eac.kafkaSubscription.Close()
	}

	eac.kafkaSubscription = subscription
	eac.log.Info("subscribe: subscription to %s ok!", eac.kafkaConfig.topic)
	return nil
}

func (eac *entityActivityCollector) Open(ctx context.Context) {
	if atomic.CompareAndSwapInt32(&eac.isOpen, 0, 1) {
		eac.log.Debug("Open: begin")
		err := RetryIfErrorLimitAttempts(ctx, eac.subscribe, time.Second*5, 3, eac.log)
		if err != nil {
			eac.log.Error("Open: error subscribing to kafka topic - %v", err)
		}
	} else {
		eac.log.Warn("Open: already opened")
	}
}

func (eac *entityActivityCollector) Close(ctx context.Context) {
	if atomic.CompareAndSwapInt32(&eac.isOpen, 1, 0) {
		eac.log.Debug("Close: begin")
		if eac.kafkaSubscription != nil {
			eac.kafkaSubscription.Close()
			eac.kafkaSubscription = nil
		}
		eac.log.Info("Close: OK")
	} else {
		eac.log.Warn("Close: already closed")
	}
}
