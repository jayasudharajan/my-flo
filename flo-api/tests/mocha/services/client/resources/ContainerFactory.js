const inversify = require('inversify');
const ClientTable = require('../../../../../dist/app/services/client/ClientTable');
const ClientService = require('../../../../../dist/app/services/client/ClientService');
const { containerModule } = require('../../../../../dist/app/services/client/container');

function ContainerFactory() {
  const container = new inversify.Container();

  ContainerFactory.loadContainerModules(container);

  return container;
}

ContainerFactory.loadContainerModules = container => {
  container.load(containerModule);
};

ContainerFactory.isLoaded = container => {
  return container.isBound(ClientService);
}

module.exports = ContainerFactory;