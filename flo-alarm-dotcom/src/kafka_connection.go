package main

import (
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

type KafkaConnection interface {
	Ping() error
	Subscribe(groupId string, topics []string, consumerFunction KafkaMessageConsumer) (KafkaSubscription, error)
	Close()
}

type KafkaSubscription interface {
	Close() //should match Closer
}

type kafkaConn struct {
	Servers   string
	Consumers []*kafkaSub
	log       Log
}

type kafkaSub struct {
	Consumer *kafka.Consumer
	GroupId  string
	Topics   []string
	_cancel  int32
	_parent  *kafkaConn
}

type KafkaMessageConsumer func(item *kafka.Message)

func CreateKafkaConnection(servers string, log Log) (KafkaConnection, error) {
	if len(servers) == 0 {
		return nil, log.Error("kafka: servers is empty")
	}

	c := new(kafkaConn)
	c.Servers = servers
	c.Consumers = make([]*kafkaSub, 0)
	c.log = log
	return c, nil
}

func (k *kafkaConn) Ping() error {
	for _, csm := range k.Consumers {
		if _, e := csm.Consumer.Subscription(); e != nil {
			return e
		}
	}
	return nil
}

func (k *kafkaConn) Subscribe(groupId string, topics []string, consumerFunction KafkaMessageConsumer) (KafkaSubscription, error) {
	if k == nil {
		return nil, k.log.Error("Subscribe: KafkaConnection is nil")
	}
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

	rv := new(kafkaSub)
	rv.Consumer = c
	rv._parent = k
	rv.GroupId = groupId
	rv.Topics = topics

	err = c.SubscribeTopics(topics, nil)
	if err != nil {
		c.Close()
		return nil, k.log.Error("Error subscribing to '%v' as '%v'. %v", topics, groupId, err)
	} else {
		k.log.Info("Listening to topic: '%v' as '%v'", topics, groupId)
	}

	// Run this in a separate thread
	go func(cn *kafkaSub) {
		defer cn.Consumer.Close()

		for {
			// Read a message with timeout, want to ensure we can break out of this loop gracefully
			msg, er := c.ReadMessage(-1)

			if er == nil {
				if msg != nil && len(msg.Value) > 2 && msg.Value[0] == '{' { //ensure valid JSON
					consumerFunction(msg)
				}
			} else {
				// The client will automatically try to recover from all errors.
				errString := strings.ToLower(er.Error())
				// Time out is an error - don't log those
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
	}(rv)

	k.Consumers = append(k.Consumers, rv)

	return rv, nil
}

func (k *kafkaSub) Close() {
	if k == nil {
		return
	}

	atomic.AddInt32(&k._cancel, 1)
	k._parent.log.Info("KafkaConnection: Consumer Close")
}

func (k *kafkaConn) Close() {
	if k == nil {
		return
	}

	if len(k.Consumers) > 0 {
		for _, c := range k.Consumers {
			c.Close()
		}
	}
}
