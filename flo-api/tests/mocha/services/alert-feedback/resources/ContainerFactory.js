const inversify = require('inversify');
const alertFeedbackContainerModule = require('../../../../../dist/app/services/alert-feedback/container').containerModule;

function ContainerFactory() {
  const container = new inversify.Container();

  container.load(alertFeedbackContainerModule);

  return container;
}

module.exports = ContainerFactory;