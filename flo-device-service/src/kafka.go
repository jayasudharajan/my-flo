package main

import (
	"context"
	"database/sql"
	"fmt"
	"strconv"
	"time"

	"golang.org/x/sync/semaphore"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/go-redis/redis/v8"
	"github.com/labstack/gommon/log"
)

const dIdKey = "did"
const lastKnownKey = "lastKnown"
const systemModeKey = "systemMode"
const unknownKey = "unknown"
const undefined = "undefined"

var _kafkaConcurrencySemaphore *semaphore.Weighted

func init() {
	maxWeight, _ := strconv.Atoi(getEnvOrDefault("FLO_KAFKA_MAX_CONCURRENT_SEM", "4"))
	if maxWeight < 2 {
		maxWeight = 2 //minimum
	}
	logNotice("FLO_KAFKA_MAX_CONCURRENT_SEM=%v", maxWeight)
	_kafkaConcurrencySemaphore = semaphore.NewWeighted(int64(maxWeight))
}

var postgresRepo PgDeviceRepository
var redisRepo RedisDeviceRepository

func InitKafkaConsumerWorkProcessing(db *sql.DB, rs *redis.ClusterClient) {
	postgresRepo.DB = db
	redisRepo.Redis = rs
}

func asyncUpdateRealTimeData(ctx context.Context, deviceId string, data map[string]interface{}) {
	err := UpdateFirestore(ctx, deviceId, data)
	if err != nil {
		log.Errorf("failed to updated deviceId_%s real time data: %v, err: %v", deviceId, data, err)
	}
}

// ConsumeKafkaMessages starts up kafka consumers
func ConsumeKafkaMessages() error {
	kc, err := initializeKafkaConsumer()
	if err != nil {
		log.Errorf("error initializing kafka consumer. %v", err)
		return err
	}

	logInfo("initialized kafka consumer")

	go func() {
		for {
			msg, err := kc.ReadMessage(-1)

			if err != nil {
				logError("ConsumeKafkaMessages: %v", err.Error())
				time.Sleep(time.Second)
				continue
			}

			if msg == nil || msg.TopicPartition.Topic == nil {
				logError("ConsumeKafkaMessages: msg or topic is nil")
				continue
			}

			// If the message is too old, do not process
			timeNow := time.Now().UTC()
			diff := timeNow.Sub(msg.Timestamp)
			if diff.Seconds() > float64(OfflineTimeThreshold) {
				logWarn("ConsumeKafkaMessages: msg too old. Msg Time: %v Current Time: %v",
					msg.Timestamp.UTC().Format(time.RFC3339),
					timeNow.Format(time.RFC3339))
				continue
			}

			// processed by work dispatcher
			topic := *msg.TopicPartition.Topic
			ctx, sp := InstaKafkaCtxExtract("ConsumeKafkaMessages", topic, &msg.Headers)
			ProcessKafkaMessageThrottled(ctx, topic, string(msg.Key), msg.Value)
			sp.Finish()
		}
	}()

	return nil
}

var _bgContext = context.Background()

func ProcessKafkaMessageThrottled(ctx context.Context, topic, key string, payload []byte) {
	logDebug("ProcessKafkaMessageThrottled: Processing %v %v, Data Length: %v", topic, key, len(payload))
	hasSem := false
	if e := _kafkaConcurrencySemaphore.Acquire(_bgContext, 1); e != nil {
		logWarn("ProcessKafkaMessageThrottled: can't acquire sem: %v", e)
		time.Sleep(time.Millisecond * 100) //back off a little
	} else {
		hasSem = true
	}

	go func(ctx context.Context, semOk bool) {
		defer panicRecover("ProcessKafkaMessageThrottled: Child routine for topic: %v %v", topic, key)

		sp := MakeSpanKafkaConsumer(ctx, "device-service process", topic, KafkaGroupId, key)
		defer sp.Finish()

		started := time.Now()
		if semOk { //will temporary use more ram to process until sem can be ack
			defer _kafkaConcurrencySemaphore.Release(1)
		}
		switch topic {
		case KafkaDevicePropertiesTopic:
			ProcessKafkaProperties(ctx, payload)
		case KafkaPresenceActivityTopic:
			ProcessPresenceKafkaMessage(ctx, payload)
		case KafkaValveStateTopic:
			ProcessValveKafkaMessage(ctx, payload)
		case KafkaSystemModeTopic:
			ProcessSystemModeKafkaMessage(ctx, payload)
		case KafkaEntityActivityTopic:
			ProcessEntityActivityTopic(ctx, payload)
		case KafkaOnboardingEventsTopic:
			ProcessOnboardingEventsTopic(ctx, payload)
		}
		logDebug("ProcessKafkaMessageThrottled: Processed %v %v OK. Took %vms", topic, key, time.Since(started).Milliseconds())
	}(ctx, hasSem)
}

func ProcessKafkaProperties(ctx context.Context, payload []byte) error {
	device, err := unmarshalDevicePropertiesPayload(payload)
	if err != nil {
		return err
	}
	return processDeviceProperties(ctx, device)
}

func initializeKafkaConsumer() (*kafka.Consumer, error) {
	brokerAddressFamily := "v4"
	enableAutoCommit := true
	var kc *kafka.Consumer
	var err error

	configMap := &kafka.ConfigMap{
		"bootstrap.servers":     KafkaBrokerUrls,
		"broker.address.family": brokerAddressFamily,
		"group.id":              KafkaGroupId,
		"session.timeout.ms":    KafkaTimeout,
		"enable.auto.commit":    enableAutoCommit,
		"auto.offset.reset":     KafkaAutoOffsetReset,
	}

	if KafkaSecurityProtocol != EmptyString {
		err := configMap.SetKey("security.protocol", KafkaSecurityProtocol)
		if err != nil {
			return nil, err
		}
		err = configMap.SetKey("ssl.ca.location", KafkaTlsCaLocation)
		if err != nil {
			return nil, err
		}
		err = configMap.SetKey("ssl.certificate.location", KafkaTlsCertLocation)
		if err != nil {
			return nil, err
		}
		err = configMap.SetKey("ssl.key.location", KafkaTlsKeyLocation)
		if err != nil {
			return nil, err
		}
		err = configMap.SetKey("ssl.key.password", KafkaTlsKeyPassword)
		if err != nil {
			return nil, err
		}
	}

	kc, err = kafka.NewConsumer(configMap)
	if err != nil {
		return nil, err
	}

	err = kc.SubscribeTopics(KafkaTopics, nil)
	if err != nil {
		return nil, err
	}

	kafkaInitMsg := "kafka consumer has been initialized with "
	msgCount := 0
	for k, v := range *configMap {
		if msgCount != len(*configMap)-1 {
			kafkaInitMsg = kafkaInitMsg + fmt.Sprintf("%s: %v, ", k, v)
		} else {
			kafkaInitMsg = kafkaInitMsg + fmt.Sprintf("%s: %v.", k, v)
		}
		msgCount++
	}

	log.Infof(kafkaInitMsg)

	return kc, nil
}
