package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

// should fit ICloser
type HeartBeatHandler interface {
	Open()
	Close()
}

// 💔 alerts
type heartBeatHandler struct {
	dCon   DeviceControl
	rQueue RingQueue
	kConn  *KafkaConnection
	kSub   *KafkaSubscription
	kGroup string
	kTopic string
	redis  *RedisConnection
	log    *Logger
	state  int32 //0=closed, 1=open
	keyDur KeyPerDuration
	resChk AllowResource
}

var _heartBeatHandlerKeyDur = CreateKeyPerDuration(time.Hour * 4) //static singleton

// meant to be used as a singleton
func CreateHeartBeatHandler(
	devControl DeviceControl,
	ringQueue RingQueue,
	kafConn *KafkaConnection,
	redis *RedisConnection,
	logger *Logger,
	resChk AllowResource) HeartBeatHandler {

	if logger == nil {
		logger = DefaultLogger()
	}
	if devControl == nil {
		logger.Fatal("CreateHeartBeatHandler: devControl is nil")
		signalExit()
		return nil
	} else if ringQueue == nil {
		logger.Fatal("CreateHeartBeatHandler: ringQueue is nil")
		signalExit()
		return nil
	} else if kafConn == nil {
		logger.Fatal("CreateHeartBeatHandler: kafConn is nil")
		signalExit()
		return nil
	}
	hb := heartBeatHandler{
		dCon:   devControl,
		rQueue: ringQueue,
		kConn:  kafConn,
		kGroup: getEnvOrDefault("FLO_KAFKA_GROUP_ID", "flo-ring-grp"),
		kTopic: getEnvOrDefault("FLO_KAFKA_TOPIC_HEART_BEAT", "device-heartbeat-status"),
		redis:  redis,
		log:    logger.CloneAsChild("heartBeatHandler"),
		keyDur: _heartBeatHandlerKeyDur, //flush every 4hours
		resChk: resChk,
	}
	hb.log.Notice("CreateHeartBeatHandler: %p OK | FLO_KAFKA_GROUP_ID=%v FLO_KAFKA_TOPIC_HEART_BEAT=%v", &hb, hb.kGroup, hb.kTopic)
	return &hb
}

func (h *heartBeatHandler) Open() {
	if h == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&h.state, 0, 1) {
		h.log.Notice("Open: begin")
		go RetryIfError(h.subscribe, time.Second*10, h.log)
	} else {
		h.log.Warn("Open: already opened")
	}
}

func (h *heartBeatHandler) subscribe() error {
	defer panicRecover(h.log, "subscribe: %p", h)
	if atomic.LoadInt32(&h.state) != 1 {
		return h.log.Warn("subscribe: can't, state is not Opened")
	} else if sub, e := h.kConn.Subscribe(h.kGroup, []string{h.kTopic}, h.consumeMessage); e != nil {
		return h.log.IfErrorF(e, "subscribe: Failed")
	} else {
		if h.kSub != nil {
			h.kSub.Close()
		}
		h.kSub = sub
		h.log.Notice("subscribe: OK!")
		return nil
	}
}

func (h *heartBeatHandler) Close() {
	if atomic.CompareAndSwapInt32(&h.state, 1, 0) {
		h.log.Debug("Close: begin")
		if h.kSub != nil {
			h.kSub.Close()
			h.kSub = nil
		}
		h.log.Notice("Close: OK")
	} else {
		h.log.Warn("Close: already closed")
	}
}

// kafka message from topic: device-heartbeat-status
type HeartBeatStatus struct {
	MacAddress string    `json:"macAddr"`
	Online     bool      `json:"online"`
	Time       time.Time `json:"time"`
}

func (hb HeartBeatStatus) String() string {
	return tryToJson(hb)
}

func (h *heartBeatHandler) consumeMessage(item *kafka.Message) {
	if len(item.Key) < 12 {
		return //bad item
	}
	defer panicRecover(h.log, "consumeMessage: mac %s", item.Key)

	if !h.resChk.Allow(string(item.Key)) {
		return
	} else if !isValidMacAddress(string(item.Key)) {
		return
	}

	ctx, _ := tracing.InstaKafkaCtxExtractWithSpan(item, "")
	var (
		beat   = HeartBeatStatus{}
		evt    *EventMessage
		notify bool
	)
	if e := json.Unmarshal(item.Value, &beat); e != nil {
		h.log.IfErrorF(e, "consumeMessage: mac %s", item.Key)
	} else if notify, e = h.canNotify(ctx, &beat); e != nil {
		h.log.IfErrorF(e, "consumerMessage: mac %s", item.Key)
	} else if !notify {
		h.log.Trace("consumeMessage: mac %s (ignore notify) | %v", item.Key, beat)
	} else if evt, e = h.dCon.HandlePropertyChange(ctx, BaseDevice{MacAddress: &beat.MacAddress}, "connectivity", "PERIODIC_POLL", beat.Time); e != nil {
		ll := LL_ERROR
		if strings.Contains(e.Error(), "Not found.") {
			if h.keyDur.Check(beat.MacAddress, time.Hour) {
				ll = LL_NOTICE
			} else { //reduce log volume for 404 as this will be repeated over & over all the time
				ll = LL_TRACE
			}
		}
		h.log.Log(ll, "consumeMessage: mac %s (propChange) | %v", item.Key, e)
	} else if evt == nil {
		h.log.Debug("consumeMessage: mac %s (sync_check) MISSING_REGISTRATION", item.Key)
	} else if e = h.rQueue.Put(ctx, evt); e != nil {
		h.log.IfErrorF(e, "consumeMessage: mac %s (queue.Put)", item.Key)
	}
}

const HEART_BEAT_TTL = time.Hour

func (h *heartBeatHandler) canNotify(ctx context.Context, beat *HeartBeatStatus) (bool, error) {
	if beat.Time.Year() <= 1 {
		return false, errors.New("bad event time")
	} else if diff := time.Since(beat.Time); diff >= HEART_BEAT_TTL {
		h.log.Trace("canNotify: IGNORE_OLD heartbeat diff %v | %v", diff, beat)
		return false, nil
	} else { //within 2hrs
		k := fmt.Sprintf("ring:heart:{%s}:evt:%v", beat.MacAddress, beat.Time.Unix())
		return h.redis.SetNX(ctx, k, fmt.Sprint(beat.Online), int(HEART_BEAT_TTL.Seconds()))
	}
}
