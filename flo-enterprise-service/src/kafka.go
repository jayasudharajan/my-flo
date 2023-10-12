package main

import (
	"context"
	"encoding/json"
	"strings"
	"sync/atomic"
	"time"

	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

type KafkaConnection struct {
	log       *Logger
	Servers   string
	Producer  *kafka.Producer
	Consumers []*KafkaSubscription
}

type KafkaSubscription struct {
	Consumer *kafka.Consumer
	GroupId  string
	Topics   []string
	_cancel  int32
	_parent  *KafkaConnection
}

type KafkaMessageConsumer func(ctx context.Context, item *kafka.Message)

func CreateKafkaConnection(log *Logger, servers string) (*KafkaConnection, error) {
	l := log.CloneAsChild("kafka")
	if len(servers) == 0 {
		return nil, l.Error("servers is empty")
	}

	p, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers":            servers,
		"go.produce.channel.size":      3000,
		"go.batch.producer":            true,
		"queue.buffering.max.kbytes":   8192,
		"queue.buffering.max.messages": 3000,
	})

	if err != nil {
		return nil, l.Error("error connecting to kafka. server = %v error = %v", servers, err)
	}

	c := new(KafkaConnection)
	c.log = l
	c.Servers = servers
	c.Producer = p
	c.Consumers = make([]*KafkaSubscription, 0)

	go func(k *KafkaConnection) {
		for {
			// Have to consume events or producer is stuck
			for e := range p.Events() {
				switch ev := e.(type) {
				case *kafka.Message:
					if ev.TopicPartition.Error != nil {
						l.Warn("delivery failed: %v", string(ev.Value))
					} else {
						l.Trace("delivered message to %v", ev.TopicPartition)
					}
				}
			}
		}
	}(c)

	return c, nil
}

func (k *KafkaConnection) Ping() error {
	for _, csm := range k.Consumers {
		if _, e := csm.Consumer.Subscription(); e != nil {
			return e
		}
	}
	return nil
}

func (k *KafkaConnection) Publish(ctx context.Context, topic string, item interface{}, optPartitionKey []byte) error {
	if k == nil || k.Producer == nil {
		return k.log.Error("Publish: KafkaConnection is nil")
	}
	if len(topic) == 0 {
		return k.log.Error("Publish: topic is empty")
	}
	if item == nil {
		return k.log.Error("Publish: item is nil")
	}

	jsonBytes, err := json.Marshal(item)

	if err != nil {
		return k.log.Error("Publish: unable to serialize item. %v", err.Error())
	}

	return k.PublishBytes(ctx, topic, jsonBytes, optPartitionKey)
}

func (k *KafkaConnection) PublishBytes(ctx context.Context, topic string, item []byte, optPartitionKey []byte) error {
	if k == nil || k.Producer == nil {
		return k.log.Error("PublishBytes: KafkaConnection is nil")
	}
	if len(topic) == 0 {
		return k.log.Error("PublishBytes: topic is empty")
	}
	if len(item) == 0 {
		return k.log.Error("PublishBytes: item is empty")
	}
	if len(optPartitionKey) == 0 {
		optPartitionKey = nil
	}

	kafkaMessage := kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
		Value:          item,
		Key:            optPartitionKey,
	}

	// inject context to message header
	kafkaMessage = *tracing.InstaKafkaCtxInsert(ctx, &kafkaMessage)
	// record a trace
	sp := tracing.InstaKafkaStartProducerSpan(ctx, &kafkaMessage, k.Servers)
	if sp != nil {
		defer sp.Finish()
	}

	k.Producer.ProduceChannel() <- &kafkaMessage

	return nil
}

func (k *KafkaConnection) Subscribe(groupId string, topics []string, consumerFunction KafkaMessageConsumer) (*KafkaSubscription, error) {
	if len(groupId) == 0 {
		return nil, k.log.Error("Subscribe: groupId is empty")
	}
	if len(topics) == 0 {
		return nil, k.log.Error("Subscribe: topics is empty")
	}
	if consumerFunction == nil {
		return nil, k.log.Error("Subscribe: consumerFunction is nil")
	}

	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers":  k.Servers,
		"group.id":           groupId,
		"enable.auto.commit": true,
		"auto.offset.reset":  "latest",
	})

	if err != nil {
		return nil, k.log.Error("error connecting to kafka. server = %v group id = %v error = %v", k.Servers, groupId, err)
	}

	rv := new(KafkaSubscription)
	rv.Consumer = c
	rv._parent = k
	rv.GroupId = groupId
	rv.Topics = topics

	err = c.SubscribeTopics(topics, nil)
	if err != nil {
		c.Close()
		return nil, k.log.Error("error subscribing to '%v' as '%v'. %v", topics, groupId, err)
	}

	k.log.Info("listening to topic: '%v' as '%v'", topics, groupId)

	// Run this in a separate thread
	go func(cn *KafkaSubscription, brokers string) {
		defer cn.Consumer.Close()

		for {
			// Read a message with timeout, want to ensure we can break out of this loop gracefully
			msg, err := c.ReadMessage(-1)

			if err == nil {
				if msg != nil && len(msg.Value) > 2 && msg.Value[0] == '{' { //ensure valid JSON
					ctx, sp := tracing.InstaKafkaCtxExtractWithSpan(msg, brokers)
					consumerFunction(ctx, msg)
					sp.Finish()
				}
			} else {
				// The client will automatically try to recover from all errors.
				errString := strings.ToLower(err.Error())
				// Time out is an error - grrr - don't log those
				if strings.Contains(errString, "timed out") {
					k.log.Info("Consumer wait found 0 msg: %v", errString)
				} else if strings.Contains(errString, "disconnected (after") {
					k.log.Notice("Consumer connection reset: %v", errString)
				} else {
					k.log.Error("Consumer error: %v", errString)
				}
				time.Sleep(time.Second) // Pause a bit on errors
			}

			// Cancel signalled
			if atomic.LoadInt32(&cn._cancel) > 0 {
				return
			}
		}
	}(rv, k.Servers)

	k.Consumers = append(k.Consumers, rv)

	return rv, nil
}

func (k *KafkaSubscription) Close() {
	atomic.AddInt32(&k._cancel, 1)
	logInfo("KafkaSubscription: Close")
}

func (k *KafkaConnection) Close() {
	if len(k.Consumers) > 0 {
		for _, c := range k.Consumers {
			c.Close()
		}
	}
}
