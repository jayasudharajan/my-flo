package main

import "time"

type WaterArchiveDocumentRecord struct {
	DeviceID   string    `dynamo:"device_id"` // see ARCHIVE_TABLE_HASH_FIELD
	TimeBucket time.Time `dynamo:"time_bucket"`
	UpdatedAt  time.Time `dynamo:"updated_at"`

	Consumption float64                 `dynamo:"consumption"`
	Seconds     int32                   `dynamo:"seconds"`
	FlowSeconds int32                   `dynamo:"flow_seconds"`
	FlowRate    float64                 `dynamo:"flow_rate"`
	Pressure    float64                 `dynamo:"pressure"`
	Temp        float64                 `dynamo:"temp"`
	Min         *WaterArchiveFuncRecord `dynamo:"min"`
	Max         *WaterArchiveFuncRecord `dynamo:"max"`
	Source      string                  `dynamo:"source"`
}

type WaterArchiveFuncRecord struct {
	FlowRate float64 `dynamo:"flow_rate"`
	Pressure float64 `dynamo:"pressure"`
	Temp     float64 `dynamo:"temp"`
}

//const (
//	WATER_ARCHIVE_ITEM_HOURLY int32 = iota
//)

const (
	ARCHIVE_TABLE_NAME        = "water_meter_archive"
	ARCHIVE_TABLE_HASH_FIELD  = "device_id"
	ARCHIVE_TABLE_RANGE_FIELD = "time_bucket"
	STD_DATE_LAYOUT           = "2006-01-02T15:04:05"
)
