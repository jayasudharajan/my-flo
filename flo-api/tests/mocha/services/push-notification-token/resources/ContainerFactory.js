const inversify = require('inversify');
const serviceContainerModule = require('../../../../../dist/app/services/push-notification-token/container').containerModule;

function ContainerFactory() {
  const container = new inversify.Container();

  container.load(serviceContainerModule);

  return container;
}

module.exports = ContainerFactory;
