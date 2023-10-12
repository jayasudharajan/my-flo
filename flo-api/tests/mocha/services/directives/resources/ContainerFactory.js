const inversify = require('inversify');
const redisContainerModule = require('../../container_modules/redis');
const kafkaContainerModule = require('../../container_modules/kafka');
const DirectiveService = require('../../../../../dist/app/services/directives/DirectiveService');
const DirectiveConfig = require('../../../../../dist/app/services/directives/DirectiveConfig');
const serviceContainerModule = require('../../../../../dist/app/services/directives/container').containerModule;
const ICDContainerFactory = require('../../icd-v1_5/resources/ContainerFactory');

function ContainerFactory() {
  const container = new inversify.Container();

  ContainerFactory.loadContainerModules(container);

  return container;
}

ContainerFactory.loadContainerModules = container => {
  container.load(
    redisContainerModule, 
    kafkaContainerModule
  );

  if (!container.isBound(DirectiveConfig)) {
    container.bind(DirectiveConfig).toConstantValue(
      new (class extends DirectiveConfig {
        getDirectivesKafkaTopic() {
          return Promise.resolve('directives-topic');
        }
    }));
  }

  if (!container.isBound(DirectiveService)) {
    container.load(serviceContainerModule);
  }

  ICDContainerFactory.loadContainerModules(container);
};

module.exports = ContainerFactory;