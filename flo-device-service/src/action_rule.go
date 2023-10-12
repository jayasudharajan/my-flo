package main

import "time"

type ActionRule struct {
	Id             string    `json:"id,omitempty"`
	TargetDeviceId string    `json:"targetDeviceId"`
	Action         string    `json:"action"`
	Event          string    `json:"event"`
	Order          int       `json:"order"`
	Enabled        bool      `json:"enabled"`
	CreatedAt      time.Time `json:"createdAt"`
	UpdatedAt      time.Time `json:"updatedAt"`
}

type ActionRules struct {
	Data []ActionRule `json:"actionRules"`
}
