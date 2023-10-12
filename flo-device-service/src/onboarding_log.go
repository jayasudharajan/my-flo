package main

import (
	"github.com/google/uuid"
	"time"
)

// OnboardingLog is the onboarding log
type OnboardingLog struct {
	Id                      uuid.UUID `json:"id,omitempty"`
	MacAddress              string    `json:"mac_address,omitempty"`
	Created                 time.Time `json:"created_at,omitempty"`
	UpdatedLastTime         time.Time `json:"updated_last_time,omitempty"`
	Event                   int       `json:"event,omitempty"`
	DeviceModel             string    `json:"device_model,omitempty"`
	DeviceType              string    `json:"device_type,omitempty"`
	IsPaired                bool      `json:"is_paired,omitempty"`
	LocationId              uuid.UUID `json:"location_id,omitempty"`
	Nickname                string    `json:"nickname,omitempty"`
	PuckConfiguredAt        time.Time `json:"puck_configured_at,omitempty"`
	RevertMinutes           int32     `json:"revert_minutes,omitempty"`
	RevertMode              string    `json:"revert_mode,omitempty"`
	RevertScheduledAt       time.Time `json:"revert_scheduled_at,omitempty"`
	ShouldInheritSystemMode bool      `json:"should_inherit_system_mode,omitempty"`
	TargetSystemMode        string    `json:"target_system_mode,omitempty"`
	TargetValveState        string    `json:"target_valve_state,omitempty"`
}

// OnboardingLogExternal is the external onboarding log
type OnboardingLogExternal struct {
	Id                      uuid.UUID `json:"id,omitempty"`
	MacAddress              string    `json:"mac_address,omitempty"`
	Created                 time.Time `json:"created_at,omitempty"`
	UpdatedLastTime         time.Time `json:"updated_last_time,omitempty"`
	Event                   int       `json:"event,omitempty"`
	DeviceModel             string    `json:"device_model,omitempty"`
	DeviceType              string    `json:"device_type,omitempty"`
	IsPaired                bool      `json:"is_paired,omitempty"`
	LocationId              uuid.UUID `json:"location_id,omitempty"`
	Nickname                string    `json:"nickname,omitempty"`
	PuckConfiguredAt        time.Time `json:"puck_configured_at,omitempty"`
	RevertMinutes           int32     `json:"revert_minutes,omitempty"`
	RevertMode              string    `json:"revert_mode,omitempty"`
	RevertScheduledAt       time.Time `json:"revert_scheduled_at,omitempty"`
	ShouldInheritSystemMode bool      `json:"should_inherit_system_mode,omitempty"`
	TargetSystemMode        string    `json:"target_system_mode,omitempty"`
	TargetValveState        string    `json:"target_valve_state,omitempty"`
}

type OnboardingLogEvent struct {
	Id       uuid.UUID `json:"id,omitempty"`
	DeviceId string    `json:"device_id,omitempty"`
	Event    LogEvent  `json:"event,omitempty"`
}

type KafkaOnboardingLogEvent struct {
	Id       string   `json:"id,omitempty"`
	DeviceId string   `json:"device_id,omitempty"`
	Event    LogEvent `json:"event,omitempty"`
}

type LogEvent struct {
	Name string `json:"name,omitempty"`
}
