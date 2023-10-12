const inversify = require('inversify');
const redisContainerModule = require('../../container_modules/redis');
const serviceContainerModule = require('../../../../../dist/app/services/icd-v1_5/container').containerModule;
const ICDService = require('../../../../../dist/app/services/icd-v1_5/ICDService');

function ContainerFactory() {
  const container = new inversify.Container();

  ContainerFactory.loadContainerModules(container);

  return container;
}

ContainerFactory.loadContainerModules = container => {
  container.load(redisContainerModule);

  if (!container.isBound(ICDService)) {
    container.load(serviceContainerModule);
  }
};

ContainerFactory.isLoaded = container => {
  return container.isBound(ICDService);
};

module.exports = ContainerFactory;