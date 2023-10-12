package main

import (
	"context"
	"crypto/sha512"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

const (
	PTYPE_PING ptype = 0
	PTYPE_PONG ptype = 1
)

type ptype int

type pingDispatcher struct {
	log         *Logger
	eventbridge AWSEventBridgeClient
	redis       *RedisConnection
	event       *EventWrapper
	ptype       ptype
}

type PingDispatcherConfig struct {
	log         *Logger
	eventbridge AWSEventBridgeClient
	redis       *RedisConnection
	event       *EventWrapper
	ptype       ptype
}

type PingPayload struct {
	At     string `json:"at"`
	Ptype  string `json:"type"`
	Value  string `json:"value"`
	Origin string `json:"origin,omitempty"`
	Id     string `json:"-"`
}

func CreatePingDispatcher(c *PingDispatcherConfig) Dispatcher {
	return &pingDispatcher{
		log:         c.log.CloneAsChild("PingDispatcher"),
		eventbridge: c.eventbridge,
		redis:       c.redis,
		event:       c.event,
		ptype:       c.ptype,
	}
}

func (d *pingDispatcher) Dispatch(ctx context.Context) (json.RawMessage, error) {
	if d == nil {
		return nil, fmt.Errorf("cannot call method Dispatch with nil pingDispatcher")
	}

	switch d.ptype {
	case PTYPE_PING:
		return d.dispatchPing(ctx)
	case PTYPE_PONG:
		return d.handleInboundPing(ctx)
	default:
		return nil, fmt.Errorf("unsupported ping type %v", d.ptype)
	}
}

func (d *pingDispatcher) handleInboundPing(ctx context.Context) (json.RawMessage, error) {
	pingPayload := PingPayload{}
	if err := json.Unmarshal(*d.event.Request.Payload, &pingPayload); err != nil {
		return nil, err
	} else if strings.EqualFold(pingPayload.Ptype, PTYPE_PING.String()) {
		return d.dispatchPong(ctx)
	} else if strings.EqualFold(pingPayload.Ptype, PTYPE_PONG.String()) {
		return d.logPongResponse(ctx, &pingPayload)
	} else {
		return nil, fmt.Errorf("unsupported ping type in payload %v", pingPayload.Ptype)
	}
}

func (d *pingDispatcher) logPongResponse(ctx context.Context, payload *PingPayload) (json.RawMessage, error) {
	d.log.Info("Received pong response from %s %v", d.event.Header.Source, payload)

	key := fmt.Sprintf("cloudsync:event:%s:pong", d.event.Header.Source)
	_, err := d.redis.Set(ctx, key, payload.At, 86400)
	if err != nil {
		return nil, err
	}
	return *d.event.Request.Payload, nil
}

func (d *pingDispatcher) dispatchPing(ctx context.Context) (json.RawMessage, error) {
	pp, err := d.createPayload()
	if err != nil {
		return nil, err
	}
	pingPayload, err := json.Marshal(pp)
	if err != nil {
		return nil, err
	}

	payload := json.RawMessage(pingPayload)
	i := &EventBridgeClientPublishInput{
		MessageType:   "ping",
		MessageAction: "created",
		Payload:       &payload,
		RequestID:     pp.Id,
	}

	err = d.eventbridge.Publish(ctx, i)
	return payload, err
}

func (d *pingDispatcher) dispatchPong(ctx context.Context) (json.RawMessage, error) {
	pp, err := d.createPayload()
	if err != nil {
		return nil, err
	}

	pongPayload, err := json.Marshal(pp)
	if err != nil {
		return nil, err
	}
	payload := json.RawMessage(pongPayload)
	i := &EventBridgeClientPublishResponseInput{
		Event:   d.event,
		Payload: &payload,
	}
	err = d.eventbridge.PublishResponse(ctx, i)
	return payload, err
}

func (d *pingDispatcher) createPayload() (*PingPayload, error) {
	var (
		at    = time.Now().UTC().Truncate(time.Second).Format(time.RFC3339)
		ptype = d.ptype.String()
	)

	uuidV4, err := uuid.NewRandom()
	if err != nil {
		return nil, err
	}

	v := at + ptype + uuidV4.String()
	value := fmt.Sprintf("%x", sha512.Sum512([]byte(v)))

	var origin string
	var requestID string
	if d.event != nil {
		origin = d.event.Header.RequestID
		requestID = origin
	} else {
		requestID = uuidV4.String()
	}

	return &PingPayload{
		At:     at,
		Ptype:  d.ptype.String(),
		Value:  value,
		Origin: origin,
		Id:     requestID,
	}, nil
}

func (pt ptype) String() string {
	switch pt {
	case PTYPE_PING:
		return "ping"
	case PTYPE_PONG:
		return "pong"
	default:
		return ""
	}
}
