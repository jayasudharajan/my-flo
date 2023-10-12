const inversify = require('inversify');
const config = require('../../../../../dist/config/config');
const EmailClient = require('../../../../../dist/app/services/utils/EmailClient');
const EmailClientMock = require('../../../utils/EmailClientMock');
const EcommerceService = require('../../../../../dist/app/services/ecommerce/EcommerceService');
const EcommerceServiceConfig = require('../../../../../dist/app/services/ecommerce/EcommerceServiceConfig');
const EcommerceController = require('../../../../../dist/app/services/ecommerce/EcommerceController');
const EcommerceRouter = require('../../../../../dist/app/services/ecommerce/routes');
const EcommerceAuthMiddleware = require('../../../../../dist/app/services/ecommerce/EcommerceAuthMiddleware');
const AuthMiddleware = require('../../../../../dist/app/services/utils/AuthMiddleware');
const ACLMiddleware = require('../../../../../dist/app/services/utils/ACLMiddleware');
const AuthMiddlewareMock = require('../../../utils/AuthMiddlewareMock');
const ACLMiddlewareMock = require('../../../utils/ACLMiddlewareMock');

function ContainerFactory() {
  const container = new inversify.Container();

  container.bind(EmailClient).toConstantValue(new EmailClientMock());
  container.bind(EcommerceAuthMiddleware).toConstantValue(new AuthMiddlewareMock());
  container.bind(AuthMiddleware).toConstantValue(new AuthMiddlewareMock());
  container.bind(ACLMiddleware).toConstantValue(new ACLMiddlewareMock());
  container.bind(EcommerceServiceConfig).toConstantValue(new EcommerceServiceConfig(config));

  container.bind(EcommerceService).to(EcommerceService);
  container.bind(EcommerceController).to(EcommerceController);
  container.bind(EcommerceRouter).to(EcommerceRouter);

	return container;
}

module.exports = ContainerFactory;

