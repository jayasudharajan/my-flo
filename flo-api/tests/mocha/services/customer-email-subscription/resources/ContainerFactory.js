const inversify = require('inversify');
const containerModule = require('../../../../../dist/app/services/customer-email-subscription/container').containerModule;

function ContainterFactory() {
  const container = new inversify.Container();

  container.load(containerModule);

  return container;
}

module.exports = ContainterFactory;