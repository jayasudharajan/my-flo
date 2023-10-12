package resourceeventprocess

import (
	"flotechnologies.com/flo-resource-event/src/commons/datefilter"
	"flotechnologies.com/flo-resource-event/src/commons/utils"
	"flotechnologies.com/flo-resource-event/src/handlers/models"
	"flotechnologies.com/flo-resource-event/src/resourceevent/resourceeventprocess/mappers"
	"flotechnologies.com/flo-resource-event/src/storages/sql/stores"
	"github.com/google/uuid"
)

type resourceEventProcessor struct {
	logger *utils.Logger
	repo   stores.ResourceEventStore
	mapper mappers.ResourceEventMapper
}

type ResourceEventProcessor interface {
	ProcessResourceEvent(resourceEvent models.ExternalResourceEvent) error
	GetAllResourceEventByAccountId(accountId uuid.UUID, dateFilter datefilter.DateFilter) ([]models.ExternalResourceEvent, error)
}

func CreateResourceEvent(
	logger *utils.Logger, repo stores.ResourceEventStore, internalResourceEventMapper mappers.ResourceEventMapper) ResourceEventProcessor {

	re := &resourceEventProcessor{
		logger.CloneAsChild("resourceEvent"),
		repo,
		internalResourceEventMapper,
	}
	return re
}

func (re *resourceEventProcessor) ProcessResourceEvent(externalResourceEvent models.ExternalResourceEvent) error {
	resourceEvent := re.mapper.ToLocalResourceEvent(externalResourceEvent)

	if e := re.repo.InsertResourceEvent(resourceEvent); e != nil {
		re.logger.IfErrorF(e, "ProcessResourceEvent: resourceId %v (accountId %v)", resourceEvent.ResourceId, resourceEvent.AccountId)
		return e
	}
	return nil
}

func (re *resourceEventProcessor) GetAllResourceEventByAccountId(accountId uuid.UUID, dateFilter datefilter.DateFilter) ([]models.ExternalResourceEvent, error) {
	data, err := re.repo.GetAllByAccountId(accountId, dateFilter)

	if err != nil {
		re.logger.IfErrorF(err, "ProcessResourceEvent: accountId %v", accountId)
		return nil, err
	}

	externalEvents := make([]models.ExternalResourceEvent, 0)

	for _, r := range data {
		ere := re.mapper.ToExternalResourceEvent(r)
		externalEvents = append(externalEvents, ere)
	}

	return externalEvents, nil
}
