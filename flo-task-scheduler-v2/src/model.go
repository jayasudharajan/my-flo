package main

import (
	"encoding/json"
	"time"

	"github.com/gorhill/cronexpr"
	"github.com/pkg/errors"
)

type TransportType string

const (
	TT_Kafka TransportType = "kafka"
	TT_Http  TransportType = "http"
)

func (t Transport) Validate() error {
	switch t.Type {
	case TT_Kafka, TT_Http:
		return nil
	}
	return errors.New("Invalid transport type")
}

func (tt *TransportType) UnmarshalJSON(b []byte) error {
	var s string
	json.Unmarshal(b, &s)
	transportType := TransportType(s)
	switch transportType {
	case TT_Kafka, TT_Http:
		*tt = transportType
		return nil
	}
	return errors.New("Invalid transport type")
}

type ScheduleType string

const (
	ST_Cron      ScheduleType = "cron"
	ST_FixedDate ScheduleType = "fixedDate"
)

func (s *Schedule) Validate() error {
	switch s.Type {
	case ST_Cron:
		var cronSchedule CronSchedule
		err := decode(s.Config, &cronSchedule)
		if err != nil {
			return errors.Wrapf(err, "Validate: error decoding cron schedule %v", s.Config)
		}
		_, err = cronexpr.Parse(cronSchedule.Expression)
		if err != nil {
			return errors.New("Invalid cron expression")
		}
		return nil
	case ST_FixedDate:
		return nil
	}
	return errors.New("Invalid schedule type")
}

func (st *ScheduleType) UnmarshalJSON(b []byte) error {
	var s string
	json.Unmarshal(b, &s)
	scheduleType := ScheduleType(s)
	switch scheduleType {
	case ST_Cron, ST_FixedDate:
		*st = scheduleType
		return nil
	}
	return errors.New("Invalid schedule type")
}

type TaskDefinition struct {
	Id        string     `json:"id"`
	Source    string     `json:"source"`
	Schedule  *Schedule  `json:"schedule"`
	Transport *Transport `json:"transport"`
}

type Transport struct {
	Type    TransportType    `json:"type"`
	Payload TransportPayload `json:"payload"`
}

type TransportPayload interface{}

type HttpTransport struct {
	Url         string  `json:"url"`
	Method      string  `json:"method"`
	ContentType *string `json:"contentType,omitempty"`
	Body        *string `json:"body,omitempty"`
}

type KafkaTransport struct {
	Topic   string `json:"topic"`
	Message string `json:"message"`
}

type Schedule struct {
	Type   ScheduleType   `json:"type"`
	Config ScheduleConfig `json:"config"`
}

type ScheduleConfig interface{}

type CronSchedule struct {
	Expression string `json:"expression"`
}

type FixedDateSchedule struct {
	Target time.Time `json:"target"`
}

type TaskStatus int

const (
	TS_Pending    TaskStatus = 1
	TS_Scheduled  TaskStatus = 2
	TS_InProgress TaskStatus = 3
	TS_Completed  TaskStatus = 4
	TS_Canceled   TaskStatus = 10
	TS_Failed     TaskStatus = 99
)

type Task struct {
	Id                string
	Definition        *TaskDefinition
	Status            TaskStatus
	NextExecutionTime time.Time
	CreatedAt         time.Time
	UpdatedAt         time.Time
}
