const inversify = require('inversify');
const serviceContainerModule = require('../../../../../dist/app/services/device-anomaly/container').containerModule;

function ContainerFactory() {
  const container = new inversify.Container();
  container.load(serviceContainerModule);
  return container;
}

module.exports = ContainerFactory;
