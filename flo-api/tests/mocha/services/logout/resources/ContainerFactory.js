const OAuth2ContainerFactory = require('../../oauth2/resources/ContainerFactory');
const PushNotificationContainerFactory = require('../../push-notification-token/resources/ContainerFactory');
const ClientContainerFactory = require('../../client/resources/ContainerFactory');
const serviceContainerModule = require('../../../../../dist/app/services/logout/container').containerModule;
const containerUtil = require('../../../../../dist/util/containerUtil');

function ContainerFactory() {
  const container = containerUtil.mergeContainers(OAuth2ContainerFactory(), PushNotificationContainerFactory());

  container.load(serviceContainerModule);

  if (!ClientContainerFactory.isLoaded(container)) {
    ClientContainerFactory.loadContainerModules(container);
  }

  return container;
}

module.exports = ContainerFactory;
