package main

import (
	"context"
	"encoding/json"
)

type RingQueueClient struct {
	logger      *Logger
	sns         SnsClient
	topic       string
	entityStore EntityStore
}

type RingQueue interface {
	Put(ctx context.Context, message *EventMessage) error
	Ping(ctx context.Context) error
}

func CreateRingQueue(log *Logger, sns SnsClient, topic string, entityStore EntityStore) RingQueue {
	return &RingQueueClient{log.CloneAsChild("RingQueueClient"), sns, topic, entityStore}
}

func (r *RingQueueClient) Put(ctx context.Context, message *EventMessage) error {
	if message == nil { //ignore it
		return nil
	}
	jsonBytes, err := json.Marshal(message)
	if err == nil {
		r.logger.Trace("Put: SNS message %v", message.Event.Header.MessageId)
		if err = r.sns.Publish(r.topic, string(jsonBytes)); err == nil { //critical ops, always publish first
			if err = r.entityStore.StoreEvent(ctx, message); err == nil {
				deviceIds := message.Event.GetEndpointIds()
				r.logger.Debug("Put: SNS event store OK %v for deviceIds %v", message.Event.Header, deviceIds)
			} else {
				r.logger.IfWarnF(err, "Put: SNS event store ERROR %v", message.Event.Header)
			}
		} else {
			r.logger.IfErrorF(err, "Put: SNS event publish ERROR %v", message.Event.Header)
		}
	} else {
		r.logger.IfErrorF(err, "Put: SNS event marshal ERROR %v", message.Event.Header)
	}
	return err
}

func (r *RingQueueClient) Ping(ctx context.Context) error {
	return r.sns.Ping(r.topic)
}
