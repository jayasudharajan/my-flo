const inversify = require('inversify');
const SystemUserDetailTable = require('../../../../../dist/app/services/system-user/SystemUserDetailTable');
const EncryptionStrategy = require('../../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../../utils/EncryptionStrategyMock');
const SystemUserService = require('../../../../../dist/app/services/system-user/SystemUserService');

function ContainterFactory() {
  const container = new inversify.Container();

  container.bind(SystemUserDetailTable).to(SystemUserDetailTable);
  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock());
  container.bind(SystemUserService).to(SystemUserService);

  return container;
}

module.exports = ContainterFactory;