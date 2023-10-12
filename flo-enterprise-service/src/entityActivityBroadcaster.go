package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
)

type EntityActivityBroadcaster interface {
	broadcastRawItem(ctx context.Context, message *EntityActivityMessage, raw *json.RawMessage) *EntityActivityBroadcasterError
}

type EntityActivityBroadcasterErrorType int

const (
	EAB_INTERNAL_ERROR EntityActivityBroadcasterErrorType = 1
	EAB_IGNORED        EntityActivityBroadcasterErrorType = 2
	EAB_PUBLISH_ERROR  EntityActivityBroadcasterErrorType = 4
)

type EntityActivityBroadcasterError struct {
	error
	errorType EntityActivityBroadcasterErrorType
}

type entityActivityBroadcaster struct {
	log                  *Logger
	redis                *RedisConnection
	awsEventBridgeClient AWSEventBridgeClient
}

func CreateEntityActivityBroadcaster(log *Logger, redis *RedisConnection, awsEventBridgeClient AWSEventBridgeClient) EntityActivityBroadcaster {
	return &entityActivityBroadcaster{
		log:                  log.CloneAsChild("entityActivityBroadcaster"),
		redis:                redis,
		awsEventBridgeClient: awsEventBridgeClient,
	}
}

func (eab *entityActivityBroadcaster) forwardToEventBridge(ctx context.Context, msg *EventBridgeClientPublishInput) error {
	return eab.awsEventBridgeClient.Publish(ctx, msg)
}

func (eab *entityActivityBroadcaster) transform(msg *EntityActivityMessage, raw *json.RawMessage) *EventBridgeClientPublishInput {
	evi := EventBridgeClientPublishInput{
		MessageType:   msg.Type,
		MessageAction: msg.Action,
		RequestID:     msg.RequestID,
		Payload:       raw,
	}
	return &evi
}

func (eab *entityActivityBroadcaster) broadcastRawItem(ctx context.Context, msg *EntityActivityMessage, raw *json.RawMessage) (eabError *EntityActivityBroadcasterError) {
	action := strings.ToLower(msg.Action)
	entity := strings.ToLower(msg.Type)
	entityId := strings.ToLower(msg.Id)

	eab.log.Debug("EntityActivityBroadcaster: acquiring lock")
	mutex := fmt.Sprintf("mutex:floEnterpriseService:eab:%s:%s:%s", entity, action, entityId)
	lockAcquired, err := eab.redis.SetNX(mutex, "", 300)
	if err != nil {
		return &EntityActivityBroadcasterError{
			error:     eab.log.Error("EntityActivityBroadcaster: error acquiring lock - %v", err),
			errorType: EAB_INTERNAL_ERROR,
		}
	}
	if !lockAcquired {
		eab.log.Trace("EntityActivityBroadcaster: lock was acquired by another instance")
		return nil // ignore and skip
	}

	defer func() {
		if err := recover(); err != nil {
			eab.log.Trace("EntityActivityBroadcaster: critical error - %v", err)
		}
		eab.log.Debug("EntityActivityBroadcaster: releasing lock")
		_, err = eab.redis.Delete(mutex)
		if err != nil {
			eabError = &EntityActivityBroadcasterError{
				error:     eab.log.Warn("EntityActivityBroadcaster: error releasing lock - %v", err),
				errorType: EAB_INTERNAL_ERROR,
			}
		}
	}()

	payload := eab.transform(msg, raw)
	if err := eab.forwardToEventBridge(ctx, payload); err != nil {
		eabError = &EntityActivityBroadcasterError{
			error:     eab.log.Warn("EntityActivityBroadcaster: error publishing to event bridge - %v", err),
			errorType: EAB_PUBLISH_ERROR,
		}
	}
	return nil
}
