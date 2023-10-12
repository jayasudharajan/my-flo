package main

import (
	"context"
	"encoding/json"
	"fmt"
)

type errorDispatcher struct {
	log         *Logger
	eventbridge AWSEventBridgeClient
	event       *EventWrapper
	message     string
	code        int64
}

type ErrorDispatcherConfig struct {
	log         *Logger
	eventbridge AWSEventBridgeClient
	event       *EventWrapper
	message     string
	code        int64
}

type ErrorAsyncResponsePayload struct {
	Code    int64  `json:"code"`
	Message string `json:"message"`
}

func CreateErrorDispatcher(c *ErrorDispatcherConfig) Dispatcher {
	return &errorDispatcher{
		log:         c.log.CloneAsChild("ErrorDispatcher"),
		eventbridge: c.eventbridge,
		event:       c.event,
		message:     c.message,
		code:        c.code,
	}
}

func (d *errorDispatcher) Dispatch(ctx context.Context) (json.RawMessage, error) {
	if d == nil {
		return nil, fmt.Errorf("cannot call method Dispatch with nil errorDispatcher")
	}
	errorPayload, err := json.Marshal(&ErrorAsyncResponsePayload{
		Message: d.message,
		Code:    d.code,
	})
	if err != nil {
		return nil, err
	}

	payload := json.RawMessage(errorPayload)
	i := &EventBridgeClientPublishResponseInput{
		Event:   d.event,
		Payload: &payload,
		Code:    d.code,
		Message: d.message,
	}
	err = d.eventbridge.PublishResponse(ctx, i)
	if err != nil {
		return nil, err
	}
	return payload, nil
}
