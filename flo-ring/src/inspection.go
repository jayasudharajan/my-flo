package main

import (
	"context"
	"errors"
	"time"
)

type MessageByDevice struct {
	DeviceId string `json:"deviceId"`
	Limit    int32  `json:"limit,omitempty"`
}

func (md MessageByDevice) String() string {
	return tryToJson(md)
}

func (md *MessageByDevice) Validate() error {
	if md == nil {
		return errors.New("nil ref")
	} else if len(md.DeviceId) != 36 {
		return errors.New("invalid device id")
	}
	return nil
}

type MessageExchanges struct {
	Params   interface{}        `json:"params"`
	Messages []*MessageExchange `json:"messages"`
}

type inspector struct {
	logger      *Logger
	entityStore EntityStore
}

type Inspector interface {
	GetMessageById(ctx context.Context, messageId string) (*MessageExchange, error)
	GetDeviceMessages(ctx context.Context, f *MessageByDevice) (*MessageExchanges, error)
}

func CreateInspector(logger *Logger, entityStore EntityStore) Inspector {
	return &inspector{logger.CloneAsChild("inspector"), entityStore}
}

func (i *inspector) GetMessageById(ctx context.Context, messageId string) (*MessageExchange, error) {
	i.logger.PushScope("Msg", messageId)
	defer i.logger.PopScope()

	d, err := i.entityStore.GetDirective(ctx, messageId)
	if err != nil {
		i.logger.IfWarnF(err, "directive fetch")
		return nil, err
	}

	var e *EventMessage
	if e, err = i.entityStore.GetEvent(ctx, messageId); err != nil {
		i.logger.IfErrorF(err, "store fetch")
		return nil, err
	}
	if d == nil && e == nil {
		return nil, nil
	}
	m := MessageExchange{Directive: d, Event: e}
	return &m, nil
}

func (i *inspector) GetDeviceMessages(ctx context.Context, f *MessageByDevice) (*MessageExchanges, error) {
	i.logger.PushScope("DeviceMsg", f.DeviceId)
	defer i.logger.PopScope()

	if er := f.Validate(); er != nil {
		i.logger.IfWarnF(er, f.String())
		return nil, er
	}
	var (
		res     = MessageExchanges{Params: f}
		arr, er = i.entityStore.GetEventsByDevice(ctx, f.DeviceId, f.Limit)
	)
	if er != nil {
		i.logger.IfErrorF(er, "store fetch")
		return nil, er
	}
	if al := len(arr); al > 0 {
		res.Messages = make([]*MessageExchange, 0, al)
		for _, e := range arr {
			var (
				d, err = i.entityStore.GetDirective(ctx, e.Event.Header.MessageId)
				dt     *time.Time
			)
			if err != nil {
				i.logger.IfWarnF(err, "directive fetch %s", e.Event.Header.MessageId)
			}
			if e.Context != nil && len(e.Context.Properties) != 0 {
				latest := time.Time{}
				for _, p := range e.Context.Properties {
					if et := tryParseTime(p.TimeOfSample); et.After(latest) {
						latest = et
					}
				}
				if latest.Year() > 2000 {
					dt = &latest
				}
			}
			res.Messages = append(res.Messages, &MessageExchange{dt, d, e})
		}
	}
	return &res, nil
}
