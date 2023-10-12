const inversify = require('inversify');
const AuthorizationContainerFactory = require('../../authorization/resources/ContainerFactory');
const UserAccountContainerFactory = require('../../user-account/resources/ContainerFactory');
const containerUtil = require('../../../../../dist/util/containerUtil');
const LocationTable = require('../../../../../dist/app/services/location-v1_5/LocationTable');
const LocationService = require('../../../../../dist/app/services/location-v1_5/LocationService');
const EncryptionStrategy = require('../../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../../utils/EncryptionStrategyMock');

function ContainerFactory() {
	const container = new inversify.Container();

	container.bind(LocationTable).to(LocationTable);
	container.bind(LocationService).to(LocationService);
	container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock());

	return [
		AuthorizationContainerFactory(),
		UserAccountContainerFactory()
	].reduce(containerUtil.mergeContainers, container);
}

module.exports = ContainerFactory;
