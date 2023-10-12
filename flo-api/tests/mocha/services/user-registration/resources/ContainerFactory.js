const inversify = require('inversify');
const UserAccountContainerFactory = require('../../user-account/resources/ContainerFactory');
const LocationContainerFactory = require('../../location-v1_5/resources/ContainerFactory');
const LegacyAuthContainerFactory = require('../../legacy-auth/resources/ContainerFactory');
const OAuth2ContainerFactory = require('../../oauth2/resources/ContainerFactory');
const AuthorizationServiceContainerFactory = require('../../authorization/resources/ContainerFactory');
const UserRegistrationTokenMetadataTable = require('../../../../../dist/app/services/user-registration/UserRegistrationTokenMetadataTable');
const UserRegistrationService = require('../../../../../dist/app/services/user-registration/UserRegistrationService');
const UserRegistrationConfig = require('../../../../../dist/app/services/user-registration/UserRegistrationConfig');
const EncryptionStrategy = require('../../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../../utils/EncryptionStrategyMock');
const EmailClient = require('../../../../../dist/app/services/utils/EmailClient');
const EmailClientMock = require('../../../utils/EmailClientMock');
const containerUtil = require('../../../../../dist/util/containerUtil');

function ContainerFactory() {
	const container = [
		UserAccountContainerFactory(),
		LocationContainerFactory(),
		LegacyAuthContainerFactory(),
		OAuth2ContainerFactory(),
		AuthorizationServiceContainerFactory()
	]
	.reduce(containerUtil.mergeContainers, new inversify.Container());

	container.rebind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password.'));
	container.bind(UserRegistrationTokenMetadataTable).to(UserRegistrationTokenMetadataTable);
	container.bind(UserRegistrationService).to(UserRegistrationService);
	container.bind(UserRegistrationConfig).toConstantValue(new (class extends UserRegistrationConfig {
		getUserRegistrationTokenTTL() {
			return Promise.resolve(30000);
		}

		getUserRegistrationTokenSecret() {
			return Promise.resolve('secret');
		}

		getMobileUserRegistrationEmailTemplateId() {
			return Promise.resolve('12345');
		}

		getWebUserRegistrationEmailTemplateId() {
			return Promise.resolve('67890');
		}

		getUserRegistrationDataTTL() {
			return Promise.resolve(30000);
		}
	}));
	container.bind(EmailClient).toConstantValue(new EmailClientMock());

	return container;
}

module.exports = ContainerFactory;

