package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	mqtt "github.com/eclipse/paho.mqtt.golang"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
)

type NotifySub interface {
	Open()
	Close()
	PingKafka() error
	PingMqtt() error
}

type notifySub struct {
	log     *Logger
	kTopic  string
	kGroup  string
	kaf     *KafkaConnection
	kSub    *KafkaSubscription
	state   int32 //0=close, 1=open
	mq      mqtt.Client
	mqTopic string //ack back topic
}

func NewNotifySub(log *Logger, kaf *KafkaConnection) NotifySub {
	ns := notifySub{
		log:     log.CloneAsChild("NS"),
		kaf:     kaf,
		kTopic:  getEnvOrDefault("FLO_KAFKA_NOTIFICATION_TOPIC", "notifications-v2"),
		kGroup:  getEnvOrDefault("FLO_KAFKA_GROUP_ID", "notification-processor"),
		mqTopic: getEnvOrDefault("FLO_MQTT_NOTIFICATION_TOPIC", "home/device/%s/v1/notifications-response/ack"),
	}
	return &ns
}

func (ns *notifySub) Open() {
	if atomic.CompareAndSwapInt32(&ns.state, 0, 1) {
		defer ns.log.Debug("Open exit")
		go RetryIfError(ns.subscribe, time.Second*20, ns.log)
	}
}

func (ns *notifySub) subscribe() error {
	if atomic.LoadInt32(&ns.state) != 1 {
		ns.log.Info("state!=1, quiting subscribe")
		return nil
	}
	var (
		e   error
		sub *KafkaSubscription
	)
	if ns.mq == nil {
		if ns.mq, e = InitMqttPublisher(); e != nil {
			return ns.log.IfWarnF(e, "subscribe: init mqtt")
		} else {
			ns.log.Notice("subscribe: init mqtt OK! at %v", getEnvOrDefault("FLO_MQTT_BROKER", "<unknown>"))
		}
	}
	if sub, e = ns.kaf.Subscribe(ns.kGroup, []string{ns.kTopic}, ns.receiveMsg); e != nil {
		return ns.log.IfErrorF(e, "subscribe: kafka")
	} else {
		ns.kSub = sub
		return nil
	}
}

func (ns *notifySub) Close() {
	if atomic.CompareAndSwapInt32(&ns.state, 1, 0) {
		defer ns.log.Debug("Close exit")
		if ns.kSub != nil {
			ns.kSub.Close()
			ns.kSub = nil
		}
		if ns.mq != nil {
			ns.mq.Disconnect(3000)
			ns.mq = nil
		}
	}
}

func (ns *notifySub) PingKafka() error {
	if atomic.LoadInt32(&ns.state) != 1 {
		return errors.New("state=0, not yet open")
	} else if e := ns.kaf.Producer.GetFatalError(); e != nil {
		return e
	} else if _, e = ns.kaf.Producer.GetMetadata(&ns.kTopic, false, 3000); e != nil {
		return e
	} else {
		return nil //probably OK
	}
}

func (ns *notifySub) PingMqtt() error {
	if atomic.LoadInt32(&ns.state) != 1 {
		return errors.New("state=0, not yet open")
	} else if ns.mq == nil {
		return errors.New("mqtt not init")
	} else if !(ns.mq.IsConnected() && ns.mq.IsConnectionOpen()) {
		return errors.New("mqtt is not connected")
	} else {
		return nil
	}
}

// SEE: https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/4259864/Notifications#Notifications-RawNotificationDatafromICD
type rawAlert struct {
	Id        string `json:"id"` //uuid
	Timestamp int64  `json:"ts"`
	Mac       string `json:"did"`
	Data      struct {
		Alarm struct {
			Id        int32 `json:"reason"`
			Timestamp int64 `json:"ht"`
			//Defer     float64 `json:"defer"`
			//Info      struct {
			//	RoundId string `json:"round_id,omitempty"` //health test round.id
			//} `json:"info,omitempty"`
			//SENS int32 `json:"sens"`
		} `json:"alarm"`
		//Snapshot struct {
		//	Timezone   string `json:"tz"`
		//	SystemMode int32  `json:"sm"`
		//	LocalTime  string `json:"lt"`
		//	//PSI        float32 `json:"p,omitempty"`
		//} `json:"snapshot"`
	} `json:"data"`
}

// notifications-v2 | {"id":"8a0787f6-a32d-11eb-9dc8-6847490cb334","ts":1619070155186,"did":"6847490cb334","data":{"alarm":{"reason":32,"ht":1619070154216,"defer":0.0,"acts":null,"info":{"round_id":"a120127a-5020-49a9-ae82-b845099e3816"},"sens":10},"snapshot":{"tz":"US/Pacific","sm":2,"lt":"22:42:34","f":0.013222465003542882,"fr":0.793347900212573,"t":145,"p":56.5,"sw1":0,"sw2":0,"ef":0.013222465003542882,"efd":1.0000217072665691}}}
// alarm-notification-status-v2 | {"ts":1619070171182,"did":"90e2020c3422","status":1,"data":{"alarm":{"reason":16,"ht":1619070169178,"defer":0.0,"acts":null,"info":null},"snapshot":{"sm":2,"f":0.04142888852715822,"fr":2.485733311629493,"t":225,"p":148.5,"sw1":1,"sw2":0,"ef":904.9317712573884,"efd":4322.999971969053}}}
func (ns *notifySub) receiveMsg(ctx context.Context, item *kafka.Message) {
	defer panicRecover(ns.log, "receiveMsg: %v", item)

	if al := len(item.Value); al > 16 && item.Value[0] == '{' && item.Value[al-1] == '}' {
		ra := rawAlert{}
		if e := json.Unmarshal(item.Value, &ra); e != nil {
			ns.log.IfErrorF(e, "receiveMsg: %s | %s", item.Key, item.Value)
		} else if len(ra.Id) < 36 {
			ns.log.Warn("receiveMsg: %s | missing id %v", item.Key, ra.Id)
		} else if ra.Data.Alarm.Id > 0 && ra.Data.Alarm.Id < 100 { // >= 100 is puck, 0 or less is invalid
			//ns.log.Trace("%s | %s", *item.TopicPartition.Topic, item.Value)
			ns.pubAck(ctx, &ra)
		}
	}
}

var (
	_alarmCritical    = []int32{10, 11, 26, 51, 52, 53, 55, 70, 71, 72, 73, 74, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89}
	_alarmWarning     = []int32{12, 13, 14, 15, 16, 18, 24, 28, 29, 30, 31, 33, 50, 57, 63, 64}
	_alarmCriticalMap = make(map[int32]bool)
	_alarmWarningMap  = make(map[int32]bool)
)

func init() {
	for _, n := range _alarmCritical {
		_alarmCriticalMap[n] = true
	}
	for _, n := range _alarmWarning {
		_alarmWarningMap[n] = true
	}
}

func (ns *notifySub) mapSeverity(alarmId int32) string {
	if _, found := _alarmCriticalMap[alarmId]; found {
		return "critical"
	} else if _, found = _alarmWarningMap[alarmId]; found {
		return "warning"
	} else {
		return "info"
	}
}

type rawAck struct {
	Id    string `json:"id"`
	Alert struct {
		Id       int32  `json:"id"`
		Severity string `json:"severity"`
	} `json:"alert"`
	Status      string `json:"status"`
	Reason      string `json:"reason"`
	ProcessedAt string `json:"processed_at"`
}

func (ra rawAck) String() string {
	return fmt.Sprintf("id:%v alrt:%v st:%v sv:%v", ra.Id, ra.Alert.Id, ra.Status, ra.Alert.Severity[:4])
}

// payload sample: {"id":"a2b6ad2e-a22c-11eb-911c-d8a98b91a884","alert":{"id":16,"severity":"warning"},"status":"filtered","reason":"sleep-mode","processed_at":"2021-04-20T23:03:38.062934"}
func (ns *notifySub) pubAck(ctx context.Context, ra *rawAlert) {
	var (
		topic = fmt.Sprintf(ns.mqTopic, ra.Mac)
		ack   = rawAck{
			Id:          ra.Id,
			Status:      "received",
			Reason:      "",
			ProcessedAt: time.Now().UTC().Format("2006-01-02T15:04:05.000000"), //"2021-04-20T23:03:38.062934"
		}
	)
	ack.Alert.Id = ra.Data.Alarm.Id
	ack.Alert.Severity = ns.mapSeverity(ra.Data.Alarm.Id)

	if buf, e := json.Marshal(&ack); e != nil {
		ns.log.IfErrorF(e, "pubAck: marshal %v mac:%v", &ack, ra.Mac)
	} else {
		_, sp := OtelSpanMqttProducer(ctx, "pubAck publish", topic, attribute.String("alert.id", ra.Id))
		tk := ns.mq.Publish(topic, byte(1), false, buf)
		if e = tk.Error(); e != nil {
			ns.log.IfErrorF(e, "pubAck: publish %v mac:%v", &ack, ra.Mac)
			sp.SetStatus(codes.Error, e.Error())
			sp.RecordError(e)
		} else {
			ns.log.Debug("pubAck: OK %v mac:%v", &ack, ra.Mac)
		}
		sp.End()
	}
}
