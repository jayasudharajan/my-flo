package mappers

import (
	"flotechnologies.com/flo-resource-event/src/handlers/models"
	"flotechnologies.com/flo-resource-event/src/resourceevent"
)

type resourceEventMapper struct{}

type ResourceEventMapper interface {
	ToLocalResourceEvent(ere models.ExternalResourceEvent) resourceevent.ResourceEvent
	ToExternalResourceEvent(re resourceevent.ResourceEvent) models.ExternalResourceEvent
}

// NewResourceEventMapper Creates a new ResourceEventMapper.
func NewResourceEventMapper() resourceEventMapper {
	return resourceEventMapper{}
}

// ToLocalResourceEvent Method to parse service ResourceEvent struct to core ResourceEvent struct.
func (resourceEventMapper) ToLocalResourceEvent(ere models.ExternalResourceEvent) resourceevent.ResourceEvent {
	result := resourceevent.ResourceEvent{
		Created:        ere.Created,
		AccountId:      ere.AccountId,
		ResourceType:   ere.ResourceType,
		ResourceAction: ere.ResourceAction,
		ResourceName:   ere.ResourceName,
		ResourceId:     ere.ResourceId,
		UserName:       ere.UserName,
		UserId:         ere.UserId,
		IpAddress:      ere.IpAddress,
		ClientId:       ere.ClientId,
		UserAgent:      ere.UserAgent,
		EventData:      ere.EventData,
	}

	return result
}

// ToExternalResourceEvent Method to parse core ResourceEvent struct to service ResourceEvent struct.
func (resourceEventMapper) ToExternalResourceEvent(re resourceevent.ResourceEvent) models.ExternalResourceEvent {
	result := models.ExternalResourceEvent{
		Created:        re.Created,
		AccountId:      re.AccountId,
		ResourceType:   re.ResourceType,
		ResourceAction: re.ResourceAction,
		ResourceName:   re.ResourceName,
		ResourceId:     re.ResourceId,
		UserName:       re.UserName,
		UserId:         re.UserId,
		IpAddress:      re.IpAddress,
		ClientId:       re.ClientId,
		UserAgent:      re.UserAgent,
		EventData:      re.EventData,
	}

	return result
}
