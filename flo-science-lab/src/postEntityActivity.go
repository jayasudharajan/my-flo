package main

import (
	"os"
	"strings"
	"time"
)

var _kafkaCnEntityActivity *KafkaConnection
var ENTITY_ACTIVITY_TOPIC string = "entity-activity-v1"

func initEntityActivity() {
	kafka, _ := OpenKafka(_kafkaCn)
	if kafka == nil {
		logError("initEntityActivity: Can't continue, exiting")
		os.Exit(-20)
	}
	_kafkaCnEntityActivity = kafka
}

func postModelActivity(action string, reason string, activity *FlosenseEntityActivity) {
	if len(action) == 0 || activity == nil || len(activity.Id) != 32 {
		return
	}
	postEntityActivity("flosense-model", action, reason, activity.Id, activity)
}

func postEntityActivity(entityType string, eventName string, reason string, primaryKey string, item interface{}) {
	if len(entityType) == 0 || len(eventName) == 0 || len(primaryKey) == 0 || item == nil {
		return
	}
	if _kafkaCnEntityActivity == nil {
		return
	}

	ea := new(EntityActivityEnvelopeModel)
	ea.Date = time.Now()
	ea.Type = strings.ToLower(strings.TrimSpace(entityType))
	ea.Action = strings.ToLower(strings.TrimSpace(eventName))
	ea.Reason = strings.ToLower(strings.TrimSpace(reason))
	ea.Id = primaryKey
	ea.Item = item

	// Partition messages for consumers to be able to optimize cache
	pkey := []byte(strings.ToLower(ea.Type + ea.Id))
	_kafkaCnEntityActivity.Publish(ENTITY_ACTIVITY_TOPIC, ea, pkey)
}

type EntityActivityEnvelopeModel struct {
	Date   time.Time   `json:"date,omitempty"`
	Type   string      `json:"type,omitempty"`
	Action string      `json:"action,omitempty"`
	Reason string      `json:"reason,omitempty"`
	Id     string      `json:"id,omitempty"`
	Item   interface{} `json:"item,omitempty"`
}

/*
	"date": "2020-01-01T00:00:00Z",
	"type": "device|location|account|user|alert",
	"action": "created|updated|deleted",
	"id": "d7fc7903-f472-4820-ace1-a91723299cfd",
	"item": { This object will vary according to the activity type }
*/
