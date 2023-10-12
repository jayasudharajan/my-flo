package main

import (
	"context"
	"encoding/json"
)

type MessageProcessor struct {
	log    *Logger
	router EventRouter
}

type MessageProcessorConfig struct {
	log    *Logger
	router EventRouter
}

func CreateMessageProcessor(c *MessageProcessorConfig) *MessageProcessor {
	return &MessageProcessor{
		log:    c.log.CloneAsChild("MessageProcessor"),
		router: c.router,
	}
}

func (r *MessageProcessor) ProcessMessage(ctx context.Context, eventBridgeMessage []byte) {
	defer panicRecover(r.log, "processMessage: MessageProcessor recovered from panic")
	ebMessage := EventBridgeMessage{}
	err := json.Unmarshal(eventBridgeMessage, &ebMessage)
	if err != nil {
		r.log.Error("processMessage: error unmarshalling event bus message %v", err.Error())
		return
	}

	message := []byte(*ebMessage.Detail)
	wrapper := EventWrapper{}
	err = json.Unmarshal(message, &wrapper)
	if err != nil {
		r.log.Error("processMessage: error unmarshalling event wrapper")
		return
	}

	err = r.router.RouteEvent(ctx, &wrapper)
	if err != nil {
		r.log.Warn("processMessage: error occurred while routing event: %v", err.Error())
	}
}
