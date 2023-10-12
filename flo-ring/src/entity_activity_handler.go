package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/pkg/errors"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

type EntityActivity struct {
	Id     string                 `json:"id"`
	Date   string                 `json:"date"`
	Type   string                 `json:"type"`
	Action string                 `json:"action"`
	Item   map[string]interface{} `json:"item"`
}

type EntityActivityKafkaConfig struct {
	KafkaConnection *KafkaConnection
	GroupId         string
	Topic           string
}

type EntityActivityAmazonConfig struct {
	RingQueue RingQueue
}

type EntityActivityProcessors struct {
	DeviceDiscovery DeviceDiscovery
	DeviceControl   DeviceControl
	AccountSync     AccountSync
}

type entityActivityHandler struct {
	logger            *Logger
	kafkaSubscription *KafkaSubscription
	kafkaConfig       *EntityActivityKafkaConfig
	redis             *RedisConnection
	amazonConfig      *EntityActivityAmazonConfig
	processors        *EntityActivityProcessors
	keyDur            KeyPerDuration
	state             int32 // 0=closed, 1=open
	store             EntityStore
	resChk            AllowResource
}

// notify when entity activity changes (device, location, account write/delete)
type EntityActivityHandler interface {
	Open()
	Close()
}

var _entityActivityHandlerKeyDur = CreateKeyPerDuration(time.Hour * 4) //static singleton

// logic is meant to be run as a singleton worker
func CreateEntityActivityHandler(
	logger *Logger,
	kafkaConfig *EntityActivityKafkaConfig,
	amazonConfig *EntityActivityAmazonConfig,
	redis *RedisConnection,
	processors *EntityActivityProcessors,
	entityStore EntityStore,
	resChk AllowResource) EntityActivityHandler {

	eah := entityActivityHandler{
		logger:            logger.CloneAsChild("entityActivity"),
		kafkaSubscription: nil,
		kafkaConfig:       kafkaConfig,
		amazonConfig:      amazonConfig,
		redis:             redis,
		processors:        processors,
		keyDur:            _entityActivityHandlerKeyDur,
		store:             entityStore,
		resChk:            resChk,
	} // flush every 4hours
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

	sub, err := eah.kafkaConfig.KafkaConnection.Subscribe(eah.kafkaConfig.GroupId, []string{eah.kafkaConfig.Topic}, eah.consumeMessage)
	if err != nil {
		return fmt.Errorf("subscribe: failed - %v", err)
	}

	if eah.kafkaSubscription != nil {
		eah.kafkaSubscription.Close()
	}

	eah.kafkaSubscription = sub
	eah.logger.Notice("subscribe: OK!")
	return nil

}

func (eah *entityActivityHandler) Close() {
	if atomic.CompareAndSwapInt32(&eah.state, 1, 0) {
		eah.logger.Debug("Close: begin")
		if eah.kafkaSubscription != nil {
			eah.kafkaSubscription.Close()
			eah.kafkaSubscription = nil
		}
		eah.logger.Notice("Close: OK")
	} else {
		eah.logger.Warn("Close: already closed")
	}
}

func (eah *entityActivityHandler) consumeMessage(m *kafka.Message) {
	defer panicRecover(eah.logger, "consumeMessage: %s", m.Key)

	var e EntityActivity
	err := json.Unmarshal(m.Value, &e)
	if err != nil {
		eah.logger.Error("entityActivityConsumer: error while deserializing entity activity message: %s - %v", m.Value, err)
		return
	}
	ctx, _ := tracing.InstaKafkaCtxExtractWithSpan(m, "")

	var msg *EventMessage
	switch strings.ToLower(e.Type) {
	case "user":
		if nLink, er := eah.processUserActivity(ctx, &e); er != nil { //error & events are handled internally already
			err = er
		} else if nLink != nil {
			eah.logger.Debug("consumeMessage: PROCESSED type:%v act:%v id:%v", e.Type, e.Action, e.Id)
		}
	case "device":
		msg, err = eah.processDeviceActivity(ctx, &e)
	case "location":
		msg, err = eah.processLocationActivity(ctx, &e)
	case "alert":
		msg, err = eah.processAlertActivity(ctx, &e)
	default:
		eah.logger.Trace("consumeMessage: type %v is ignored", e.Type)
	}

	if err != nil {
		ll := LL_ERROR
		if strings.Contains(err.Error(), "Not found.") {
			if eah.keyDur.Check(fmt.Sprintf("err:%s:%s", e.Type, e.Id), time.Hour) {
				ll = LL_WARN
			} else { //reduce log volume for not found items
				ll = LL_TRACE
			}
		}
		eah.logger.Log(ll, "consumeMessage: ERROR while processing %s change with id %s - %v", e.Type, e.Id, err)
		return
	}
	if msg == nil {
		return
	}
	eah.logger.Debug("consumeMessage: QUEUED type:%v act:%v id:%v", e.Type, e.Action, e.Id)
	if err = eah.amazonConfig.RingQueue.Put(ctx, msg); err != nil {
		eah.logger.Error("consumeMessage: ERROR putting event to queue for change with id %s - %v", e.Id, err)
		return
	}
}

func (eah *entityActivityHandler) processUserActivity(ctx context.Context, e *EntityActivity) (*LinkOpsRes, error) {
	if strings.EqualFold(e.Action, "deleted") {
		if found, err := eah.store.UserExists(ctx, e.Id); err != nil {
			return nil, err
		} else if found {
			return eah.processors.AccountSync.UnLinkUser(ctx, e.Id, "") //do this as an admin for user token maybe revoked
		}
	}
	return nil, nil
}

func (eah *entityActivityHandler) processDeviceActivity(ctx context.Context, e *EntityActivity) (*EventMessage, error) {
	var d Device
	if err := jsonMap(e.Item, &d); err != nil {
		return nil, fmt.Errorf("processDeviceActivity: error while decoding item: %v - %v", e.Item, err)
	} else if !isDeviceTypeDiscoverable(d.DeviceType) || !eah.resChk.Allow(d.MacAddress) {
		return nil, nil //debug ignore
	}

	switch act := strings.ToLower(e.Action); act {
	case "deleted":
		if found, _ := eah.store.DeviceExists(ctx, e.Id, d.MacAddress); !found {
			return nil, nil
		}
		return eah.processors.DeviceDiscovery.BuildDeleteReportForDevice(ctx, &d)
	case "created", "updated":
		if act == "updated" && d.Valve != nil {
			// Omit valve state changes triggered through PubGW.
			// See valve_state_handler.go
			return nil, nil
		}
		return eah.processors.DeviceDiscovery.BuildAddOrUpdateReportForDevice(ctx, e.Id)
	default:
		return nil, nil //ignore action
	}
}

func (eah *entityActivityHandler) processLocationActivity(ctx context.Context, e *EntityActivity) (*EventMessage, error) {
	var l Location
	if err := jsonMap(e.Item, &l); err != nil {
		return nil, fmt.Errorf("error while decoding item: %v - %v", e.Item, err)
	} else if !eah.resChk.Allow(l.Id) {
		return nil, nil //debug ignore
	}
	switch strings.ToLower(e.Action) {
	case "deleted":
		return eah.processors.DeviceDiscovery.BuildDeleteReportForLocation(ctx, &l)
	case "created", "updated":
		return eah.processors.DeviceDiscovery.BuildAddOrUpdateReportForLocation(ctx, e.Id)
	default:
		return nil, nil //ignore action
	}
}

func (eah *entityActivityHandler) allowAlert(a Alert) bool {
	switch strings.ToLower(a.Alarm.Severity) {
	case "critical", "warning":
		return true
	default:
		return false
	}
}

func (eah *entityActivityHandler) processAlertActivity(ctx context.Context, e *EntityActivity) (*EventMessage, error) {
	if strings.EqualFold(e.Action, "updated") { //ignore all alert updates
		return nil, nil
	}
	var a Alert
	if err := jsonMap(e.Item, &a); err != nil {
		return nil, fmt.Errorf("error while decoding item: %v - %v", e.Item, err)
	} else if mac := Str(a.Device.MacAddress); mac != "" && !eah.resChk.Allow(mac) {
		return nil, nil //debug ignore
	} else if did := Str(a.Device.Id); did != "" && !eah.resChk.Allow(did) {
		return nil, nil //debug ignore
	}
	if eah.allowAlert(a) {
		if ok, e := eah.canNotify(ctx, &a); e != nil {
			return nil, e
		} else if ok {
			t := a.Updated.Time()
			if t.Year() < 2000 {
				t = a.Created.Time()
			}
			eah.logger.Debug("processAlertActivity: %v", a)
			return eah.processors.DeviceControl.HandlePropertyChange(ctx, a.Device, "deviceAlertsDetectionState", "UNKNOWN", t)
		}
	}
	return nil, nil // Omit non-critical alerts
}

const ALERT_TTL = time.Hour * 2

func (eah *entityActivityHandler) canNotify(ctx context.Context, a *Alert) (bool, error) {
	if created := a.Created.Time(); created.Year() <= 2000 {
		return false, errors.New("bad event time")
	} else if diff := time.Since(created); diff >= ALERT_TTL {
		eah.logger.Trace("canNotify: IGNORE_OLD alerts diff %v | %v", diff, a)
		return false, nil
	} else { //within 2hrs
		k := fmt.Sprintf("ring:alert:{%s}:evt", a.Id)
		return eah.redis.SetNX(ctx, k, a.Status, int(ALERT_TTL.Seconds()))
	}
}
