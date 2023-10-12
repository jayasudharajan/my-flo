package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/eventbridge"
	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
)

type AWSEventBridgeClient interface {
	Publish(ctx context.Context, publishInput *EventBridgeClientPublishInput) error
	PublishResponse(ctx context.Context, publishResponseInput *EventBridgeClientPublishResponseInput) error
	Ping(ctx context.Context) error
}

type awsEventBridgeClient struct {
	log      *Logger
	config   *AWSEventBridgeConfig
	client   *eventbridge.EventBridge
	validate *validator.Validate
}

type AWSEventBridgeConfig struct {
	log          *Logger
	eventBusName string
	source       string
	session      *session.Session
}

func CreateAWSEventBridgeClient(config *AWSEventBridgeConfig) AWSEventBridgeClient {
	svc := eventbridge.New(config.session)

	return &awsEventBridgeClient{
		log:      config.log.CloneAsChild("AWSEventBridgeClient"),
		config:   config,
		client:   svc,
		validate: validator.New(),
	}
}

type EventBridgeClientPublishInput struct {
	MessageType   string           `validate:"required"`
	MessageAction string           `validate:"required"`
	Payload       *json.RawMessage `validate:"required"`
	RequestID     string
}

func (c *awsEventBridgeClient) Publish(ctx context.Context, publishInput *EventBridgeClientPublishInput) (err error) {
	if c == nil {
		return fmt.Errorf("calling Publish on nil AWSEventBridgeClient")
	} else if publishInput == nil {
		return fmt.Errorf("publish recieved nil input")
	}
	defer panicRecover(c.log, "Publish: %v", publishInput)

	if err = c.validate.Struct(publishInput); err != nil {
		return
	}
	var (
		header = c.createHeader(publishInput.RequestID)
		event  = c.createEvent(publishInput.MessageType, publishInput.MessageAction, header, publishInput.Payload)
		buf    []byte
	)
	if buf, err = json.Marshal(event); err != nil {
		c.log.IfErrorF(err, "Publish: failed to marshal message")
		return
	}
	eb := eventbridge.PutEventsRequestEntry{}
	eb.SetEventBusName(c.config.eventBusName)
	eb.SetSource(c.config.source)
	eb.SetDetail(string(buf))
	eb.SetDetailType("Sync event from Flo Technologies")

	c.log.Trace("Attempting to publish %v", event)
	var (
		results *eventbridge.PutEventsOutput
		inp     = eventbridge.PutEventsInput{Entries: []*eventbridge.PutEventsRequestEntry{&eb}}
	)

	if results, err = c.client.PutEventsWithContext(ctx, &inp); err != nil {
		c.log.IfErrorF(err, "Publish: error publishing to event bridge")
		return
	}

	ebResultID := ""
	if len(results.Entries) > 0 {
		if entry := results.Entries[0]; entry != nil && entry.EventId != nil {
			ebResultID = *entry.EventId
		}
	}
	c.log.Debug("Publish: successfully published event %v to event bridge %v %v %v",
		ebResultID, header.RequestID, publishInput.MessageType, publishInput.MessageAction)
	return
}

type EventBridgeClientPublishResponseInput struct {
	Event   *EventWrapper    `validate:"required"`
	Code    int64            `validate:"required"`
	Payload *json.RawMessage `validate:"required"`
	Message string
}

func (c *awsEventBridgeClient) PublishResponse(ctx context.Context, publishResponseInput *EventBridgeClientPublishResponseInput) error {
	if c == nil {
		return fmt.Errorf("calling PublishResponse on nil AWSEventBridgeClient")
	}
	if publishResponseInput == nil {
		c.log.Error("PublishResponse: received nil input")
		return fmt.Errorf("publish response recieved nil input")
	}
	defer panicRecover(c.log, "PublishResponse: %v", publishResponseInput)

	err := c.validate.Struct(*publishResponseInput)
	if err != nil {
		return err
	}

	event := publishResponseInput.Event
	event.Response = c.createResponse(publishResponseInput.Payload, publishResponseInput.Code, publishResponseInput.Message)

	e, err := json.Marshal(event)
	if err != nil {
		c.log.IfErrorF(err, "PublishResponse: failed to marshal message")
		return err
	}

	eb := eventbridge.PutEventsRequestEntry{}
	eb.SetEventBusName(c.config.eventBusName)
	eb.SetSource(c.config.source)
	eb.SetDetail(string(e))
	eb.SetDetailType("Sync response from Flo Technologies")

	c.log.Trace("Attempting to publish %v", event)

	results, err := c.client.PutEventsWithContext(ctx, &eventbridge.PutEventsInput{
		Entries: []*eventbridge.PutEventsRequestEntry{&eb},
	})
	if err != nil {
		c.log.IfErrorF(err, "PublishResponse: error publishing to event bridge")
		return err
	}

	ebResultID := ""
	if len(results.Entries) > 0 {
		ebResultID = *results.Entries[0].EventId
	}
	c.log.Debug("PublishResponse: successfully published response %v to event bridge %v", ebResultID, event.Header.RequestID)
	return nil
}

func (c *awsEventBridgeClient) createHeader(requestID string) *EventRequestHeader {
	if requestID == "" {
		uuidV4, err := uuid.NewRandom()
		if err != nil {
			c.log.IfErrorF(err, "createHeader: error generating request id for header")
		}

		requestID = uuidV4.String()
	}

	return &EventRequestHeader{
		RequestID: requestID,
		Timestamp: time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		Source:    c.config.source,
	}
}

func (c *awsEventBridgeClient) createEvent(messageType string, messageAction string, header *EventRequestHeader, payload *json.RawMessage) *EventWrapper {
	return &EventWrapper{
		Header: header,
		Request: &EventRequestBody{
			Entity:  messageType,
			Action:  messageAction,
			Payload: payload,
		},
	}
}

func (c awsEventBridgeClient) Ping(ctx context.Context) (err error) {
	pingDesc := getEnvOrDefault("FLO_CLOUD_SYNC_EVENT_BRIDGE_PING_DESC", "")
	if strings.EqualFold(pingDesc, "true") { //if true, ping by desc (this was the original logic)
		input := &eventbridge.DescribeEventBusInput{
			Name: aws.String(c.config.eventBusName),
		}
		_, err = c.client.DescribeEventBus(input)
	} else { // by default, send a test message because account might not have "describe" access!
		var (
			reqId   = uuid.New().String()
			now     = time.Now().Format(TIME_FMT_PUBGW_MS)
			hash, _ = mh3(fmt.Sprintf("%v:%v", reqId, now))
			pay     = PingPayload{
				At:     now,
				Ptype:  "0",
				Value:  hash,
				Origin: reqId,
				Id:     reqId,
			}
			buf json.RawMessage
		)
		if buf, err = json.Marshal(&pay); err == nil {
			inp := EventBridgeClientPublishInput{
				MessageType:   "ping",
				MessageAction: "created",
				Payload:       &buf,
				RequestID:     reqId,
			}
			if err = c.Publish(ctx, &inp); err == nil {
				c.log.Trace("Ping OK!")
			}
		}
	}
	c.log.IfErrorF(err, "eventBridgePing")
	return
}

func (c *awsEventBridgeClient) createResponse(payload *json.RawMessage, code int64, message string) *EventResponseBody {
	return &EventResponseBody{
		Timestamp: time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		Payload:   payload,
		Code:      code,
		Message:   message,
	}
}
