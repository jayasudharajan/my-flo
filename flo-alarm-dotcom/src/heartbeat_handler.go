package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

// HeartBeatHandler should fit ICloser
type HeartBeatHandler interface {
	Open()
	Close()
}

//💔 alerts
type heartBeatHandler struct {
	kConn       KafkaConnection
	kSub        KafkaSubscription
	kGroup      string
	kTopic      string
	log         Log
	state       int32 //0=closed, 1=open
	keyDur      KeyPerDuration
	newNotifier StatNotifyManagerFactory
}

var _heartBeatHandlerKeyDur = CreateKeyPerDuration(time.Hour * 2) //static singleton

// CreateHeartBeatHandler meant to be used as a singleton
func CreateHeartBeatHandler(
	kafConn KafkaConnection,
	logger Log,
	newNotifier StatNotifyManagerFactory) HeartBeatHandler {

	if logger == nil {
		logger = DefaultLogger()
	}
	hb := heartBeatHandler{
		kConn:       kafConn,
		kGroup:      getEnvOrDefault("FLO_KAFKA_GROUP_ID", DEFAULT_KAFKA_GROUP),
		kTopic:      getEnvOrDefault("FLO_KAFKA_TOPIC_HEART_BEAT", "device-heartbeat-status"),
		log:         logger,
		keyDur:      _heartBeatHandlerKeyDur, //flush every 4hours
		newNotifier: newNotifier,
	}
	if hb.log.IsDebug() {
		hb.kGroup += "-debug"
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

// HeartBeatStatus kafka message from topic: device-heartbeat-status
type HeartBeatStatus struct {
	MacAddress string    `json:"macAddr"`
	Online     bool      `json:"online"`
	Time       time.Time `json:"time"`
}

func (hb HeartBeatStatus) String() string {
	return tryToJson(hb)
}

func validKafkaMacKey(item *kafka.Message) bool {
	if item == nil || !isValidMacAddress(string(item.Key)) || len(item.Value) < 32 || item.Value[0] != '{' {
		return false
	} else {
		return true
	}
}

func (h *heartBeatHandler) consumeMessage(item *kafka.Message) {
	if !validKafkaMacKey(item) {
		return
	}
	defer panicRecover(h.log, "consumeMessage: mac %s", item.Key)
	var (
		beat   = HeartBeatStatus{}
		notify bool
	)
	if e := json.Unmarshal(item.Value, &beat); e != nil {
		h.log.IfErrorF(e, "consumeMessage: mac %s", item.Key)
	} else if notify, e = h.canNotify(&beat); e != nil {
		h.log.IfErrorF(e, "consumerMessage: mac %s", item.Key)
	} else if !notify {
		h.log.Trace("consumeMessage: mac %s (ignore notify) | %s", item.Key, item.Value)
	} else {
		h.log.Trace("consumeMessage: OK %v %v @ %v",
			beat.MacAddress, IfTrue(beat.Online, "online", "offline"), beat.Time.Format(time.RFC3339))
		reporter := h.newNotifier()
		reporter.OnAliveSignal(&beat)
	}
}

const HEART_BEAT_TTL = time.Hour

func (h *heartBeatHandler) canNotify(beat *HeartBeatStatus) (bool, error) {
	if beat.Time.Year() <= 1 {
		return false, errors.New("bad event time")
	} else if diff := time.Since(beat.Time); diff >= HEART_BEAT_TTL {
		return false, nil
	} else { //within 2hrs
		key := fmt.Sprintf("hb:%v", strings.ToLower(beat.MacAddress))
		return h.keyDur.Check(key, HEART_BEAT_TTL), nil
	}
}
