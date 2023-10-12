const inversify = require('inversify');
const UserAccountContainerFactory = require('../../user-account/resources/ContainerFactory');
const ClientContainerFactory = require('../../client/resources/ContainerFactory');
const MultifactorAuthenticationContainerFactory = require('../../multifactor-authentication/resources/ContainerFactory');
const AuthenticationService = require('../../../../../dist/app/services/authentication/AuthenticationService');
const UserLoginAttemptTable = require('../../../../../dist/app/services/authentication/UserLoginAttemptTable');
const UserLockStatusTable = require('../../../../../dist/app/services/authentication/UserLockStatusTable');
const containerUtil = require('../../../../../dist/util/containerUtil');


function ContainerFactory() {
  const container = new inversify.Container();

  container.bind(UserLoginAttemptTable).to(UserLoginAttemptTable);
  container.bind(UserLockStatusTable).to(UserLockStatusTable);
  container.bind(AuthenticationService).to(AuthenticationService);

  return [
    UserAccountContainerFactory(), 
    ClientContainerFactory(),
    MultifactorAuthenticationContainerFactory()
  ].reduce(containerUtil.mergeContainers, container);
}

module.exports = ContainerFactory;