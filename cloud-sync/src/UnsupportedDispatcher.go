package main

import (
	"context"
	"encoding/json"
)

type UnsupportedDispatcher struct {
	log   *Logger
	event *EventWrapper
}

type UnsupportedDispatcherConfig struct {
	log   *Logger
	event *EventWrapper
}

func CreateUnsupportedDispatcher(c *UnsupportedDispatcherConfig) Dispatcher {
	return &UnsupportedDispatcher{
		log:   c.log.CloneAsChild("UnsupportedDispatcher"),
		event: c.event,
	}
}

func (d *UnsupportedDispatcher) Dispatch(ctx context.Context) (json.RawMessage, error) {
	d.log.Trace("Dispatch: Skipping unsupported event %v %v %v %v", d.event.Request.Entity, d.event.Request.Action, d.event.Header.Source, d.event.Header.RequestID)

	return json.RawMessage{}, nil
}

type UnsupportedRouter struct {
	log *Logger
}

func CreateUnsupportedRouter(log *Logger) Router {
	return &UnsupportedRouter{
		log: log.CloneAsChild("UnsupportedRouter"),
	}
}

func (r *UnsupportedRouter) CreateDispatcher(ctx context.Context, event *EventWrapper) (Dispatcher, error) {
	return CreateUnsupportedDispatcher(&UnsupportedDispatcherConfig{
		log:   r.log,
		event: event,
	}), nil
}
