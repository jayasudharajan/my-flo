package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
)

type MoenRouter struct {
	log                    *Logger
	pubGwURL               string
	authHeader             *StringPairs
	eventbridge            AWSEventBridgeClient
	redis                  *RedisConnection
	moenAuthSvc            MoenAuthService
	pubGwDispatcherFactory *PublicGatewayDispatcherFactory
}

type MoenRouterConfig struct {
	log         *Logger
	http        HttpUtil
	floAPIToken string
	pubGwURL    string
	eventbridge AWSEventBridgeClient
	redis       *RedisConnection
	moenAuthSvc MoenAuthService
}

func CreateMoenRouter(c *MoenRouterConfig) *MoenRouter {
	moenRouterLog := c.log.CloneAsChild("MoenRouter")
	pubGwDispatcherConfig := &PublicGatewayDispatcherFactoryConfig{
		log:       moenRouterLog,
		http:      c.http,
		authToken: c.floAPIToken,
	}
	return &MoenRouter{
		log:         moenRouterLog,
		pubGwURL:    c.pubGwURL,
		eventbridge: c.eventbridge,
		redis:       c.redis,
		authHeader: &StringPairs{
			Name:  AUTH_HEADER,
			Value: c.floAPIToken,
		},
		moenAuthSvc:            c.moenAuthSvc,
		pubGwDispatcherFactory: CreatePublicGatewayDispatcherFactory(pubGwDispatcherConfig),
	}
}

func (r *MoenRouter) CreateDispatcher(ctx context.Context, event *EventWrapper) (Dispatcher, error) {
	if r == nil {
		return nil, fmt.Errorf("CreateDispatcher: cannot call method on nil MoenRouter")
	} else if event == nil {
		return nil, fmt.Errorf("CreateDispatcher: CreateDispatcher received an empty event")
	}

	switch strings.ToLower(event.Request.Entity) {
	case PTYPE_PING.String():
		return r.createPingDispatcher(event)
	case EVENT_TYPE_USER:
		if strings.EqualFold(event.Request.Action, EVENT_ACTION_CREATED) {
			return r.createUnsupportedDispatcher(event)
		}
		return r.createPublicGatewayDispatcher(ctx, event)
	default:
		return r.createUnsupportedDispatcher(event)
	}
}

func (r *MoenRouter) createPingDispatcher(event *EventWrapper) (Dispatcher, error) {
	return CreatePingDispatcher(&PingDispatcherConfig{
		log:         r.log,
		eventbridge: r.eventbridge,
		redis:       r.redis,
		ptype:       PTYPE_PONG,
		event:       event,
	}), nil
}

func (r *MoenRouter) createUnsupportedDispatcher(event *EventWrapper) (Dispatcher, error) {
	return CreateUnsupportedDispatcher(&UnsupportedDispatcherConfig{
		log:   r.log,
		event: event,
	}), nil
}

func (r *MoenRouter) createPublicGatewayDispatcher(ctx context.Context, event *EventWrapper) (Dispatcher, error) {
	var (
		payload     *json.RawMessage
		method, url string
		err         error
	)
	if method, err = r.getMethodFromEvent(event); err != nil {
		return nil, err
	} else if url, err = r.getURLFromEvent(ctx, event); err != nil {
		return nil, err
	}
	if method == HTTP_POST {
		if payload, err = r.getPayloadFromEvent(ctx, event); err != nil {
			return nil, err
		}
	}
	cfg := PublicGatewayDispatcherConfig{
		method:      method,
		url:         url,
		requestBody: payload,
		requestID:   event.Header.RequestID,
	}
	d := r.pubGwDispatcherFactory.New(&cfg)
	return d, nil
}

func (r *MoenRouter) getURLFromEvent(ctx context.Context, event *EventWrapper) (string, error) {
	url := ""
	switch strings.ToLower(event.Request.Entity) {
	case EVENT_TYPE_USER:
		usr := MoenUserModel{}
		err := json.Unmarshal(*event.Request.Payload, &usr)
		if err != nil {
			return "", err
		}

		id, err := r.moenAuthSvc.GetFloUserId(ctx, usr.FederatedId)
		if err != nil {
			return "", err
		}

		url = r.pubGwURL + "/api/v2/users/" + id
	case EVENT_TYPE_ALARM_SETTINGS:
		usr := MoenEntityAlarmSettingsModel{}
		err := json.Unmarshal(*event.Request.Payload, &usr)
		if err != nil {
			return "", err
		}

		id, err := r.moenAuthSvc.GetFloUserId(ctx, usr.FederatedId)
		if err != nil {
			return "", err
		}

		url = r.pubGwURL + "/api/v2/users/" + id + "/alarmSettings"
	default:
		return "", fmt.Errorf("unsupported event entity type")
	}

	return url, nil

}

func (r *MoenRouter) getMethodFromEvent(event *EventWrapper) (string, error) {
	switch strings.ToLower(event.Request.Action) {
	case EVENT_ACTION_CREATED:
		return HTTP_POST, nil
	case EVENT_ACTION_UPDATED:
		return HTTP_POST, nil
	case EVENT_ACTION_DELETED:
		return HTTP_DELETE, nil
	default:
		return "", fmt.Errorf("unsupported event action")
	}
}

func (r *MoenRouter) getPayloadFromEvent(ctx context.Context, event *EventWrapper) (*json.RawMessage, error) {
	switch strings.ToLower(event.Request.Entity) {
	case EVENT_TYPE_USER:
		return r.fromUserPayload(event.Request.Payload)
	case EVENT_TYPE_ALARM_SETTINGS:
		return r.fromAlertSettingsPayload(event.Request.Payload)
	default:
		return nil, fmt.Errorf("unsupported event entity type")
	}
}

func (r *MoenRouter) fromUserPayload(payload *json.RawMessage) (*json.RawMessage, error) {
	var (
		usr = MoenUserModel{}
		err = json.Unmarshal(*payload, &usr)
	)
	if err != nil {
		return nil, err
	}

	var (
		pay json.RawMessage
		m   = usr.ToPublicGatewayModel()
	)
	pay, err = json.Marshal(m)
	if ps := string(pay); ps == "" || ps == "null" || ps == "{}" {
		return nil, &HttpErr{400, "No Mapped User Changes to Update", false, nil}
	}
	return &pay, nil
}

func (r *MoenRouter) fromAlertSettingsPayload(payload *json.RawMessage) (*json.RawMessage, error) {
	settings := MoenEntityAlarmSettingsModel{}
	err := json.Unmarshal(*payload, &settings)

	if err != nil {
		return nil, err
	}

	p := json.RawMessage{}
	p, err = json.Marshal(settings)
	return &p, nil
}
