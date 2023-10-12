package main

import (
	"encoding/json"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

type KafkaConnection struct {
	Producer      *kafka.Producer
	Servers       string
	Consumers     []*KafkaSubscription
	EventCallback KafkaProducerEvents
}

type KafkaSubscription struct {
	Consumer *kafka.Consumer
	GroupId  string
	Topics   []string
	_cancel  int32
	_parent  *KafkaConnection
}

type KafkaMessageConsumer func(item *kafka.Message)
type KafkaProducerEvents func(event kafka.Event)

func OpenKafka(servers string, producerCallback KafkaProducerEvents) (*KafkaConnection, error) {
	if len(servers) == 0 {
		return nil, logError("KafkaConsumer: servers is empty")
	}

	// Connect to Kafka as a producer
	// Connect to Kafka
	p, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers":            servers,
		"go.produce.channel.size":      3000,
		"go.batch.producer":            true,
		"queue.buffering.max.kbytes":   8192,
		"queue.buffering.max.messages": 3000,
	})

	if err != nil {
		return nil, logError("error connecting to kafka. server = %v error = %v", servers, err.Error())
	}

	rv := new(KafkaConnection)
	rv.Producer = p
	rv.Servers = servers
	rv.Consumers = make([]*KafkaSubscription, 0)
	rv.EventCallback = producerCallback

	go func(k *KafkaConnection) {
		for {
			// Have to consume events or producer is stuck
			e := <-k.Producer.Events()
			if k.EventCallback != nil {
				k.EventCallback(e)
			}
		}
	}(rv)

	return rv, nil
}

func (k *KafkaConnection) Publish(topic string, item interface{}, optPartitionKey []byte) error {
	if k == nil || k.Producer == nil {
		return logError("Publish: KafkaConnection is nil")
	}
	if len(topic) == 0 {
		return logError("Publish: topic is empty")
	}
	if item == nil {
		return logError("Publish: item is nil")
	}

	jsonBytes, err := json.Marshal(item)

	if err != nil {
		return logError("Publish: unable to serialize item. %v", err.Error())
	}

	return k.PublishBytes(topic, jsonBytes, optPartitionKey)
}

func (k *KafkaConnection) PublishBytes(topic string, item []byte, optPartitionKey []byte) error {
	if k == nil || k.Producer == nil {
		return logError("PublishBytes: KafkaConnection is nil")
	}
	if len(topic) == 0 {
		return logError("PublishBytes: topic is empty")
	}
	if len(item) == 0 {
		return logError("PublishBytes: item is empty")
	}
	if len(optPartitionKey) == 0 {
		optPartitionKey = nil
	}

	kafkaMessage := kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
		Value:          item,
		Key:            optPartitionKey,
	}

	k.Producer.ProduceChannel() <- &kafkaMessage

	return nil
}

func (k *KafkaConnection) Subscribe(groupId string, topics []string, processFunction KafkaMessageConsumer) (*KafkaSubscription, error) {
	if k == nil {
		return nil, logError("Subscribe: KafkaConnection is nil")
	}
	if len(groupId) == 0 {
		return nil, logError("Subscribe: groupId is empty")
	}
	if len(topics) == 0 {
		return nil, logError("Subscribe: topics is empty")
	}
	if processFunction == nil {
		return nil, logError("Subscribe: processFunction is nil")
	}

	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers":  k.Servers,
		"group.id":           groupId,
		"enable.auto.commit": true,
		"auto.offset.reset":  "latest",
	})

	if err != nil {
		return nil, logError("error connecting to kafka. server = %v group id = %v error = %v", k.Servers, groupId, err.Error())
	}

	rv := new(KafkaSubscription)
	rv.Consumer = c
	rv._parent = k
	rv.GroupId = groupId
	rv.Topics = topics

	err = c.SubscribeTopics(topics, nil)
	if err != nil {
		c.Close()
		return nil, logError("Error subscribing to '%v' as '%v'. %v", topics, groupId, err.Error())
	} else {
		logInfo("Listening to topic: '%v' as '%v'", topics, groupId)
	}

	// Run this in a separate thread
	go func(cn *KafkaSubscription) {
		defer cn.Consumer.Close()

		for {
			// Read a message with timeout, want to ensure we can break out of this loop gracefully
			msg, err := c.ReadMessage(-1)

			if err == nil {
				processFunction(msg)
			} else {
				// The client will automatically try to recover from all errors.
				errString := err.Error()

				// Time out is an error - grrr - don't log those
				if !strings.Contains(errString, "Timed out") {
					logError("Consumer error: %v\n", errString)
					// Pause a bit on errors
					time.Sleep(time.Second)
				}
			}

			// Cancel signalled
			if atomic.LoadInt32(&cn._cancel) > 0 {
				return
			}
		}
	}(rv)

	k.Consumers = append(k.Consumers, rv)

	return rv, nil
}

func (k *KafkaSubscription) Close() {
	if k == nil {
		return
	}

	atomic.AddInt32(&k._cancel, 1)
	logInfo("KafkaConnection: Consumer Close")
}

func (k *KafkaConnection) Close() {
	if k == nil {
		return
	}

	if len(k.Consumers) > 0 {
		for _, c := range k.Consumers {
			c.Close()
		}
	}

	logInfo("KafkaConnection: Producer Close")
	k.Producer.Flush(2000)
}
