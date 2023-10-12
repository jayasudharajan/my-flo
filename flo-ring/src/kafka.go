package main

import (
	"context"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

type KafkaConnection struct {
	Servers   string
	Consumers []*KafkaSubscription
}

type KafkaSubscription struct {
	Consumer *kafka.Consumer
	GroupId  string
	Topics   []string
	_cancel  int32
	_parent  *KafkaConnection
}

type KafkaMessageConsumer func(item *kafka.Message)

func CreateKafkaConnection(servers string) (*KafkaConnection, error) {
	if len(servers) == 0 {
		return nil, logError("kafka: servers is empty")
	}

	c := new(KafkaConnection)
	c.Servers = servers
	c.Consumers = make([]*KafkaSubscription, 0)
	return c, nil
}

func (k *KafkaConnection) Ping(ctx context.Context) error {
	for _, csm := range k.Consumers {
		if _, e := csm.Consumer.Subscription(); e != nil {
			return e
		}
	}
	return nil
}

func (k *KafkaConnection) Subscribe(groupId string, topics []string, consumerFunction KafkaMessageConsumer) (*KafkaSubscription, error) {
	if k == nil {
		return nil, logError("Subscribe: KafkaConnection is nil")
	}
	if len(groupId) == 0 {
		return nil, logError("Subscribe: groupId is empty")
	}
	if len(topics) == 0 {
		return nil, logError("Subscribe: topics is empty")
	}
	if consumerFunction == nil {
		return nil, logError("Subscribe: consumerFunction is nil")
	}

	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers":  k.Servers,
		"group.id":           groupId,
		"enable.auto.commit": true,
		"auto.offset.reset":  "latest",
	})

	if err != nil {
		return nil, logError("error connecting to kafka. server = %v group id = %v error = %v", k.Servers, groupId, err)
	}

	rv := new(KafkaSubscription)
	rv.Consumer = c
	rv._parent = k
	rv.GroupId = groupId
	rv.Topics = topics

	err = c.SubscribeTopics(topics, nil)
	if err != nil {
		c.Close()
		return nil, logError("Error subscribing to '%v' as '%v'. %v", topics, groupId, err)
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
				if msg != nil && len(msg.Value) > 2 && msg.Value[0] == '{' { //ensure valid JSON
					consumerFunction(msg)
				}
			} else {
				// The client will automatically try to recover from all errors.
				errString := strings.ToLower(err.Error())
				// Time out is an error - grrr - don't log those
				if strings.Contains(errString, "timed out") {
					logInfo("Consumer wait found 0 msg: %v", errString)
				} else if strings.Contains(errString, "disconnected (after") {
					logNotice("Consumer connection reset: %v", errString)
				} else {
					logError("Consumer error: %v", errString)
				}
				time.Sleep(time.Second) // Pause a bit on errors
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
}
