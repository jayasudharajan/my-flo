const inversify = require('inversify');
const MultifactorAuthenticationService = require('../../../../../dist/app/services/multifactor-authentication/MultifactorAuthenticationService');
const MultifactorAuthenticationConfig = require('../../../../../dist/app/services/multifactor-authentication/MultifactorAuthenticationConfig');
const UserMultifactorAuthenticationSettingTable = require('../../../../../dist/app/services/multifactor-authentication/UserMultifactorAuthenticationSettingTable');
const MultifactorAuthenticationTokenMetadataTable = require('../../../../../dist/app/services/multifactor-authentication/MultifactorAuthenticationTokenMetadataTable');
const EncryptionStrategy = require('../../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../../utils/EncryptionStrategyMock');
const UserAccountContainerFactory = require('../../user-account/resources/ContainerFactory');
const containerUtil = require('../../../../../dist/util/containerUtil');


function ContainerFactory() {
  const container = new inversify.Container();

  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password'));

  container.bind(UserMultifactorAuthenticationSettingTable).to(UserMultifactorAuthenticationSettingTable);
  container.bind(MultifactorAuthenticationService).to(MultifactorAuthenticationService);
  container.bind(MultifactorAuthenticationTokenMetadataTable).to(MultifactorAuthenticationTokenMetadataTable);

  container.bind(MultifactorAuthenticationConfig).toConstantValue(
    new (class extends MultifactorAuthenticationConfig {
      getMFATokenTTL() {
        return Promise.resolve(3000);
      }

      getMFATokenSecret() {
        return Promise.resolve('secret');
      }
    }));

  return [
    UserAccountContainerFactory()
  ].reduce(containerUtil.mergeContainers, container);
}

module.exports = ContainerFactory;