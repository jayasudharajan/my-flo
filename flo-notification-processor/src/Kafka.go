package main

import (
	"context"
	"encoding/json"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/etf1/opentelemetry-go-contrib/instrumentation/github.com/confluentinc/confluent-kafka-go/otelconfluent"
	"go.opentelemetry.io/otel"
)

type KafkaConnection struct {
	Producer      *otelconfluent.Producer
	Servers       string
	Consumers     []*KafkaSubscription
	EventCallback KafkaProducerEvents
}

type KafkaSubscription struct {
	Consumer *otelconfluent.Consumer
	GroupId  string
	Topics   []string
	_cancel  int32
	_parent  *KafkaConnection
}

type KafkaMessageConsumer func(ctx context.Context, item *kafka.Message)
type KafkaProducerEvents func(event kafka.Event)

func OpenKafka(servers string, producerCallback KafkaProducerEvents) (*KafkaConnection, error) {
	if len(servers) == 0 {
		return nil, _log.Error("KafkaConsumer: servers is empty")
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
		return nil, _log.Error("error connecting to kafka. server = %v error = %v", servers, err.Error())
	}

	pt := otelconfluent.NewProducerWithTracing(p, otelconfluent.WithTracerProvider(otel.GetTracerProvider()))

	rv := new(KafkaConnection)
	rv.Producer = pt
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

func (k *KafkaConnection) Publish(ctx context.Context, topic string, item interface{}, optPartitionKey []byte) error {
	if k == nil || k.Producer == nil {
		return _log.Error("Publish: KafkaConnection is nil")
	}
	if len(topic) == 0 {
		return _log.Error("Publish: topic is empty")
	}
	if item == nil {
		return _log.Error("Publish: item is nil")
	}

	jsonBytes, err := json.Marshal(item)

	if err != nil {
		return _log.Error("Publish: unable to serialize item. %v", err.Error())
	}

	return k.PublishBytes(ctx, topic, jsonBytes, optPartitionKey)
}

func (k *KafkaConnection) PublishBytes(ctx context.Context, topic string, item []byte, optPartitionKey []byte) error {
	if k == nil || k.Producer == nil {
		return _log.Error("PublishBytes: KafkaConnection is nil")
	}
	if len(topic) == 0 {
		return _log.Error("PublishBytes: topic is empty")
	}
	if len(item) == 0 {
		return _log.Error("PublishBytes: item is empty")
	}
	if len(optPartitionKey) == 0 {
		optPartitionKey = nil
	}

	kafkaMessage := kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
		Value:          item,
		Key:            optPartitionKey,
	}

	otel.GetTextMapPropagator().Inject(ctx, otelconfluent.NewMessageCarrier(&kafkaMessage))

	k.Producer.ProduceChannel() <- &kafkaMessage

	return nil
}

func (k *KafkaConnection) Subscribe(groupId string, topics []string, processFunction KafkaMessageConsumer) (*KafkaSubscription, error) {
	if k == nil {
		return nil, _log.Error("Subscribe: KafkaConnection is nil")
	}
	if len(groupId) == 0 {
		return nil, _log.Error("Subscribe: groupId is empty")
	}
	if len(topics) == 0 {
		return nil, _log.Error("Subscribe: topics is empty")
	}
	if processFunction == nil {
		return nil, _log.Error("Subscribe: processFunction is nil")
	}

	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers":  k.Servers,
		"group.id":           groupId,
		"enable.auto.commit": true,
		"auto.offset.reset":  "latest",
	})

	if err != nil {
		return nil, _log.Error("error connecting to kafka. server = %v group id = %v error = %v", k.Servers, groupId, err.Error())
	}

	ct := otelconfluent.NewConsumerWithTracing(c, otelconfluent.WithTracerProvider(otel.GetTracerProvider()))

	rv := new(KafkaSubscription)
	rv.Consumer = ct
	rv._parent = k
	rv.GroupId = groupId
	rv.Topics = topics

	err = c.SubscribeTopics(topics, nil)
	if err != nil {
		c.Close()
		return nil, _log.Error("Error subscribing to '%v' as '%v'. %v", topics, groupId, err.Error())
	} else {
		_log.Notice("Listening to topic: '%v' as '%v'", topics, groupId)
	}

	// Run this in a separate thread
	go func(cn *KafkaSubscription) {
		defer cn.Consumer.Close()

		for {
			// Read a message with timeout, want to ensure we can break out of this loop gracefully
			msg, err := c.ReadMessage(-1)

			if err == nil {
				// extract context from message header
				ctx := otel.GetTextMapPropagator().Extract(context.Background(), otelconfluent.NewMessageCarrier(msg))
				processFunction(ctx, msg)
			} else {
				// The client will automatically try to recover from all errors.
				errString := err.Error()

				// Time out is an error - grrr - don't log those
				if !strings.Contains(strings.ToLower(errString), "timed out") {
					_log.Error("Consumer error: %v", errString)
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
	_log.Notice("KafkaConnection: Consumer Close")
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

	_log.Notice("KafkaConnection: Producer Close")
	k.Producer.Flush(2000)
}
