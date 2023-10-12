package models

import "time"

type TaskType string

const (
	Type_FWPropertiesProvisioning TaskType = "provision_fw_properties"
)

type TaskStatus int

const (
	TS_Pending    TaskStatus = 1
	TS_InProgress TaskStatus = 2
	TS_Completed  TaskStatus = 4
	TS_Failed     TaskStatus = 8
)

type Task struct {
	Id         string
	MacAddress *string
	Type       TaskType
	Status     TaskStatus
	CreatedAt  time.Time
	UpdatedAt  time.Time
}
