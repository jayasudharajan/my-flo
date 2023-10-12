package main

import (
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
	"strings"
)

type EntityActivityMessage struct {
	Id        string          `json:"id"`
	Date      string          `json:"date"`
	Type      string          `json:"type"`
	Action    string          `json:"action"`
	RequestID string          `json:"requestId"`
	Item      json.RawMessage `json:"item"`
}

// NormalizeRequestID creates or fixes request ids that don't fit the format. If the provided request id does not have enough characters to be fixed, a new one will be generated.
func (m *EntityActivityMessage) NormalizeRequestID() *EntityActivityMessage {
	if m == nil {
		return nil
	}
	normalizedRequestID, err := uuid.Parse(m.RequestID)
	if err != nil {
		m.RequestID = uuid.New().String()
		return m
	}
	m.RequestID = normalizedRequestID.String()
	return m
}

// ToPayload method is no longer use? maybe remove later
func (m *EntityActivityMessage) ToPayload() (payload json.RawMessage, err error) {
	switch m.Type {
	case EVENT_TYPE_LOCATION:
		t := FloActivityLocation{}
		if err = json.Unmarshal(m.Item, &t); err != nil {
			return nil, err
		}
		return json.Marshal(t)
	case EVENT_TYPE_DEVICE:
		t := FloActivityDevice{}
		if err = json.Unmarshal(m.Item, &t); err != nil {
			return nil, err
		}
		return json.Marshal(t)
	case EVENT_TYPE_USER:
		if strings.EqualFold(m.Action, ENTITY_ACTIVITY_ACTION_LINKED) || strings.EqualFold(m.Action, ENTITY_ACTIVITY_ACTION_UNLINKED) {
			t := FloActivityEnvelope{}
			if err = json.Unmarshal(m.Item, &t); err != nil {
				return nil, err
			}
			return json.Marshal(t)
		}
	case EVENT_TYPE_ALERT:
		t := FloActivityAlert{}
		if err = json.Unmarshal(m.Item, &t); err != nil {
			return nil, err
		}
		return json.Marshal(t)
	}
	return nil, fmt.Errorf("unsupported entity activity message %v %v %v", m.Type, m.Action, m.RequestID)
}

func (m EntityActivityMessage) String() string {
	return tryToJson(m)
}
