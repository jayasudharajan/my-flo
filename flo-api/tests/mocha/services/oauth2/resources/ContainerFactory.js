const UserAccountContainerFactory = require('../../user-account/resources/ContainerFactory');
const AuthenticationContainerFactory = require('../../authentication/resources/ContainerFactory');
const AuthorizationContainerFactory = require('../../authorization/resources/ContainerFactory');
const ClientContainerFactory = require('../../client/resources/ContainerFactory');
const AccessTokenMetadataTable = require('../../../../../dist/app/services/oauth2/AccessTokenMetadataTable');
const RefreshTokenMetadataTable = require('../../../../../dist/app/services/oauth2/RefreshTokenMetadataTable');
const AuthorizationCodeMetadataTable = require('../../../../../dist/app/services/oauth2/AuthorizationCodeMetadataTable');
const ScopeTable = require('../../../../../dist/app/services/oauth2/ScopeTable');
const OAuth2Config = require('../../../../../dist/app/services/oauth2/OAuth2Config');
const OAuth2Service = require('../../../../../dist/app/services/oauth2/OAuth2Service');
const containerUtil = require('../../../../../dist/util/containerUtil');
const ACLService = require('../../../../../dist/app/services/utils/ACLService');
const ACLServiceMock = require('../../../utils/ACLServiceMock');
const Logger = require('../../../../../dist/app/services/utils/Logger');

function ContainerFactory() {
  const container = containerUtil.mergeContainers(
  	UserAccountContainerFactory(),
  	AuthenticationContainerFactory(),
    AuthorizationContainerFactory()
  );

  if (!ClientContainerFactory.isLoaded(container)) {
    ClientContainerFactory.loadContainerModule(container);
  }

  container.bind(AccessTokenMetadataTable).to(AccessTokenMetadataTable);
  container.bind(RefreshTokenMetadataTable).to(RefreshTokenMetadataTable);
  container.bind(AuthorizationCodeMetadataTable).to(AuthorizationCodeMetadataTable);
  container.bind(OAuth2Service).to(OAuth2Service);
  container.bind(ScopeTable).to(ScopeTable);
  container.bind(Logger).toConstantValue(new Logger());
  container.bind(OAuth2Config).toConstantValue(new (class extends OAuth2Config {

  	getAccessTokenSecret() { return Promise.resolve('access token secret'); }

  	getRefreshTokenSecret() { return Promise.resolve('refresh token secret'); }

  	getAccessTokenTTL() { return Promise.resolve(30000); }

  	getRefreshTokenTTL() { return Promise.resolve(30000); }

    getRefreshTokenLimit() { return Promise.resolve(3); }

    getAuthorizationCodeTTL() {
      return Promise.resolve(30000);
    }

    getAuthorizationCodeSecret() {
      return Promise.resolve('authorization code secret');
    }

    getRefreshTokenLinger() {
      return Promise.resolve(3);
    }

  }));

  container.rebind(ACLService).toConstantValue(new (class extends ACLServiceMock {
    userRoles(userId) {
      return Promise.resolve([]);
    }

    areAnyRolesAllowed(userId, resource, permission) {
      return Promise.resolve(false);
    }
  }));

  return container;
}

module.exports = ContainerFactory;