const SystemUserContainerFactory = require('../../system-user/resources/ContainerFactory');
const authorizationContainerModule = require('../../../../../dist/app/services/authorization/container').containerModule;
const ACLService = require('../../../../../dist/app/services/utils/ACLService');
const ACLServiceMock = require('../../../utils/ACLServiceMock');

function ContainterFactory() {
  const container = SystemUserContainerFactory();

  container.bind(ACLService).toConstantValue(new ACLServiceMock());

  container.load(authorizationContainerModule);

  return container;
}

module.exports = ContainterFactory;