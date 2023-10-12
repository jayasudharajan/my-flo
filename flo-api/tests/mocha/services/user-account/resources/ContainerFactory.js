const AuthorizationContainerFactory = require('../../authorization/resources/ContainerFactory');
const UserTable = require('../../../../../dist/app/services/user-account/UserTable');
const UserDetailTable = require('../../../../../dist/app/services/user-account/UserDetailTable');
const AccountTable = require('../../../../../dist/app/services/account-v1_5/AccountTable');
const LocationTable = require('../../../../../dist/app/services/location-v1_5/LocationTable');
const AccountService = require('../../../../../dist/app/services/location-v1_5/LocationService');
const LocationService = require('../../../../../dist/app/services/account-v1_5/AccountService');
const UserAccountService = require('../../../../../dist/app/services/user-account/UserAccountService');
const EncryptionStrategy = require('../../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../../utils/EncryptionStrategyMock');

function ContainterFactory() {
  const container = AuthorizationContainerFactory();
  container.bind(UserTable).to(UserTable);
  container.bind(UserDetailTable).to(UserDetailTable);
  container.bind(AccountTable).to(AccountTable);
  container.bind(LocationTable).to(LocationTable);
  container.bind(LocationService).to(LocationService);
  container.bind(AccountService).to(AccountService);
  container.bind(UserAccountService).to(UserAccountService);
  container.rebind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password'));

  return container;
}

module.exports = ContainterFactory;