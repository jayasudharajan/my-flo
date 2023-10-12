package resourceevent

import (
	"time"

	"flotechnologies.com/flo-resource-event/src/commons/enums"
	"flotechnologies.com/flo-resource-event/src/commons/utils"
	"github.com/google/uuid"
)

// ResourceEvent is a model from business layer
type ResourceEvent struct {
	Created        time.Time
	AccountId      uuid.UUID
	ResourceType   enums.ResourceType
	ResourceAction enums.ResourceAction
	ResourceName   string
	ResourceId     uuid.UUID
	UserName       string
	UserId         uuid.UUID
	IpAddress      string
	ClientId       uuid.UUID
	UserAgent      string
	EventData      utils.JSONB
}
