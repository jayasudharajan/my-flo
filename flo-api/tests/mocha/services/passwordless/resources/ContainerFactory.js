const uuid = require('uuid');
const inversify = require('inversify');
const UserAccountContainerFactory = require('../../user-account/resources/ContainerFactory');
const OAuth2ContainerFactory = require('../../oauth2/resources/ContainerFactory');
const AuthenticationContainerFactory = require('../../authentication/resources/ContainerFactory');
const AuthorizationContainerFactory = require('../../authorization/resources/ContainerFactory');
const PasswordlessService = require('../../../../../dist/app/services/passwordless/PasswordlessService');
const PasswordlessController = require('../../../../../dist/app/services/passwordless/PasswordlessController')
const PasswordlessRouter = require('../../../../../dist/app/services/passwordless/routes');
const PasswordlessClientTable = require('../../../../../dist/app/services/passwordless/PasswordlessClientTable')
const PasswordlessConfig = require('../../../../../dist/app/services/passwordless/PasswordlessConfig');
const EmailClient = require('../../../../../dist/app/services/utils/EmailClient');
const EmailClientMock = require('../../../utils/EmailClientMock');
const containerUtil = require('../../../../../dist/util/containerUtil');

function ContainerFactory() {
	const container = new inversify.Container();

	container.bind(PasswordlessService).to(PasswordlessService);
	container.bind(PasswordlessController).to(PasswordlessController);
	container.bind(PasswordlessRouter).to(PasswordlessRouter);
	container.bind(PasswordlessClientTable).to(PasswordlessClientTable);
	container.bind(EmailClient).toConstantValue(new EmailClientMock());
	container.bind(PasswordlessConfig).toConstantValue(new (class extends PasswordlessConfig {
	getMagicLinkTemplateId() {
			return Promise.resolve('abcd1234');
		}

		getRedirectURL() {
			return Promise.resolve('localhost:8000/api/v1/passwordless');
		}

		getMagicLinkMobileURI() {
			return Promise.resolve('floapp://login');
		}		

		getPasswordlessClientId() {
			return Promise.resolve(uuid.v4());
		}
	}));


	return [
		UserAccountContainerFactory(),
		OAuth2ContainerFactory(),
		AuthenticationContainerFactory(),
		AuthorizationContainerFactory()
	].reduce(containerUtil.mergeContainers, container);
}

module.exports = ContainerFactory;