package main

import "time"

type WaterMeterAttribute struct {
	ID        string
	Value     string
	UpdatedAt time.Time
}

const (
	WATER_METER_ATTRIBUTE_ARCHIVE_START = "archive_start_date"
	WATER_METER_ATTRIBUTE_ARCHIVE_END   = "archive_end_date"
	WATER_METER_ATTRIBUTE_LIVE_START    = "live_data_start_date"
)
