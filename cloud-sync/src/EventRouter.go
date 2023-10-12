package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
)

type EventRouter interface {
	RouteEvent(ctx context.Context, event *EventWrapper) error
}

type Router interface {
	CreateDispatcher(ctx context.Context, event *EventWrapper) (Dispatcher, error)
}

type Dispatcher interface {
	Dispatch(ctx context.Context) (json.RawMessage, error)
}

type eventRouter struct {
	log               *Logger
	moenSource        string
	moenRouter        Router
	unsupportedRouter Router
	redis             *RedisConnection
	validate          *validator.Validate
	eventbridge       AWSEventBridgeClient
}

type EventRouterConfig struct {
	log               *Logger
	moenSource        string
	moenRouter        Router
	unsupportedRouter Router
	redis             *RedisConnection
	eventbridge       AWSEventBridgeClient
}

func CreateEventRouter(c *EventRouterConfig) EventRouter {
	return &eventRouter{
		log:               c.log.CloneAsChild("EventRouter"),
		moenSource:        c.moenSource,
		moenRouter:        c.moenRouter,
		unsupportedRouter: c.unsupportedRouter,
		redis:             c.redis,
		validate:          validator.New(),
		eventbridge:       c.eventbridge,
	}
}

func (er *eventRouter) RouteEvent(ctx context.Context, event *EventWrapper) (err error) {
	defer panicRecover(er.log, "RouteEvent: %p", &er)
	if er == nil {
		return fmt.Errorf("calling RouteEvent on nil EventRouter")
	} else if event == nil {
		err = fmt.Errorf("required parameter event is nil")
		return er.log.IfWarnF(err, "RouteEvent: cannot route")
	} else if event.Response != nil {
		return er.handleResponse(event)
	}

	if err = er.validate.Struct(*event); err != nil {
		var (
			errMessage = fmt.Sprintf("Recieved event failed validation: %v", err.Error())
			cfg        = ErrorDispatcherConfig{
				log:         er.log,
				eventbridge: er.eventbridge,
				event:       event,
				message:     errMessage,
				code:        400,
			}
			errDispatcher = CreateErrorDispatcher(&cfg)
		)
		if _, e := errDispatcher.Dispatch(ctx); e != nil {
			er.log.IfErrorF(e, "RouteEvent: error occurred while dispatching")
		}
		return err
	}

	var (
		key            = fmt.Sprintf("mutex:cloudsync:event:request:%v", event.Header.RequestID)
		requestLockSet bool
	)
	if requestLockSet, err = er.redis.SetNX(ctx, key, event.Header.Source, 30); err != nil {
		er.log.IfErrorF(err, "RouteEvent: Error setting lock for request %v", event.Header.RequestID)
		return err
	} else if !requestLockSet {
		er.log.Trace("RouteEvent: lock acquired by another instance %v", event.Header.RequestID)
		return fmt.Errorf("could not route duplicate request with id %v", event.Header.RequestID)
	}

	var (
		r        = er.determineRouterBySource(event)
		d        Dispatcher
		response json.RawMessage
	)
	if d, err = r.CreateDispatcher(ctx, event); err != nil {
		er.log.IfErrorF(err, "RouteEvent: Error creating dispatcher %v", event.Header.RequestID)
		return err
	} else if response, err = d.Dispatch(ctx); err != nil {
		er.log.IfErrorF(err, "RouteEvent: Error dispatching %v", event.Header.RequestID)
		ep := ErrorPayload{Type: "Dispatch Error", Message: err.Error()}
		if errLog, e := json.Marshal(ep); e != nil {
			er.log.IfErrorF(e, "RouteEvent: failed to marshal error message for response log")
		} else {
			er.cacheResponse(ctx, event.Header.RequestID, string(errLog))
		}
		return err
	}
	er.cacheResponse(ctx, event.Header.RequestID, string(response))
	return nil
}

func (er *eventRouter) determineRouterBySource(event *EventWrapper) Router {
	switch strings.ToLower(event.Header.Source) {
	case er.moenSource:
		return er.moenRouter
	default:
		return er.unsupportedRouter
	}
}

func (er *eventRouter) cacheResponse(ctx context.Context, requestID string, response string) {
	var (
		key  = fmt.Sprintf("cloudsync:event:receive:response:log:%v", requestID)
		ttls = (time.Hour * 24).Seconds()
	)
	if _, err := er.redis.Set(ctx, key, response, int(ttls)); err != nil {
		er.log.Error("cacheResponse: Error saving receive response log to redis %v %v", err, requestID)
	}
}

func (er *eventRouter) handleResponse(event *EventWrapper) error {
	if event.Response.Code >= 400 {
		er.log.Error("Received error response: %v", event)
		return nil
	}

	er.log.Info("Received response: %v", event)
	return nil
}
