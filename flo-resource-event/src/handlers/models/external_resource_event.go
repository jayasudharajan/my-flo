package models

import (
	"time"

	"flotechnologies.com/flo-resource-event/src/commons/enums"
	"flotechnologies.com/flo-resource-event/src/commons/utils"
	"github.com/google/uuid"
)

type ExternalResourceEvent struct {
	Created        time.Time            `json:"created" validate:"required"`
	AccountId      uuid.UUID            `json:"accountId" validate:"required"`
	ResourceType   enums.ResourceType   `json:"resourceType" validate:"required,min=1,max=36"`
	ResourceAction enums.ResourceAction `json:"resourceAction" validate:"required,min=1,max=36"`
	ResourceName   string               `json:"resourceName" validate:"required,min=1,max=256"`
	ResourceId     uuid.UUID            `json:"resourceId" validate:"required"`
	UserName       string               `json:"userName" validate:"required,min=1,max=256"`
	UserId         uuid.UUID            `json:"userId" validate:"omitempty"`
	IpAddress      string               `json:"ipAddress" validate:"omitempty,max=256"`
	ClientId       uuid.UUID            `json:"clientId" validate:"omitempty"`
	UserAgent      string               `json:"userAgent" validate:"omitempty,max=256"`
	EventData      utils.JSONB          `json:"eventData"`
}

func (e ExternalResourceEvent) String() string {
	return utils.TryToJson(e)
}