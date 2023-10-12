package main

import (
	"context"
	"encoding/json"
	"strings"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

const batchWriteThreshold = 4

var kafkaSubscription *KafkaSubscription

func InitKafkaConsumer(kafkaConnection *KafkaConnection) error {
	subscription, err := kafkaConnection.Subscribe(KafkaGroupId, []string{KafkaFirestoreWriterTopic}, consumeFirestoreMessage)
	if err != nil {
		return logError("subscribe: subscription to %s failed - %v", KafkaFirestoreWriterTopic)
	}

	if kafkaSubscription != nil {
		kafkaSubscription.Close()
	}

	kafkaSubscription = subscription
	logInfo("SubscribeToKafka: subscription to %s ok!", KafkaFirestoreWriterTopic)
	return nil
}

func consumeFirestoreMessage(m *kafka.Message) {
	topic := *m.TopicPartition.Topic

	ctx, sp := InstaKafkaCtxExtract(topic, KafkaBrokerUrls, m.Headers)
	defer sp.Finish()

	if strings.HasPrefix(topic, "_") {
		return
	}

	logDebug("consumeFirestoreMessage: received kafka message %s on %s topic", string(m.Value), KafkaFirestoreWriterTopic)

	err := queueFirestoreMessage(ctx, topic, m.Value)
	if err != nil {
		logError("consumeFirestoreMessage: %v", err.Error())
	}
}

func queueFirestoreMessage(ctx context.Context, topic string, message []byte) error {
	if len(message) < 2 {
		return logError("queueFirestoreMessage: message is empty")
	}

	payload := message
	logDebug("queueFirestoreMessage: %v", string(message))
	if len(payload) > 0 {
		data, err := unmarshalTelemetryPayload(payload)
		if collectionI, ok := data[CollectionKey]; ok {
			if err != nil {
				logError("queueFirestoreMessage: failed to unmarshal kafka msg payload %v, err: %v", string(payload), err)
			}
			if c, okC := collectionI.(string); okC {
				sp := MakeSpanKafkaConsumer(ctx, "queueFirestoreMessage", topic, KafkaBrokerUrls)
				workRequest := WorkRequest{
					Data:       data,
					Collection: c,
				}
				logDebug("submitting work request %v", workRequest)
				QueueWork(workRequest)
				sp.Finish()
			} else {
				logError("queueFirestoreMessage: failed to cast c interface to string %v", collectionI)
			}
		} else {
			logError("queueFirestoreMessage: missing collection attribute in the kafka message payload, dropping the message")
		}
	} else {
		logWarn("queueFirestoreMessage: kafka msg payload is 0")
	}

	return nil
}

func unmarshalTelemetryPayload(requestPayload []byte) (map[string]interface{}, error) {
	var payload map[string]interface{}
	err := json.Unmarshal(requestPayload, &payload)
	if err != nil {
		return nil, err
	}
	return payload, nil
}

func QueueWork(item WorkRequest) {
	_workRequestChannel[item.Collection] <- item
}
