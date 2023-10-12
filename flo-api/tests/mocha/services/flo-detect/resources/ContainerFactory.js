const inversify = require('inversify');
const serviceContainerModule = require('../../../../../dist/app/services/flo-detect/container').containerModule;
const ACLMiddleware = require('../../../../../dist/app/services/utils/ACLMiddleware');
const ACLMiddlewareMock = require('../../../utils/ACLMiddlewareMock');
const AuthMiddleware = require('../../../../../dist/app/services/utils/AuthMiddleware');
const AuthMiddlewareMock = require('../../../utils/AuthMiddlewareMock');
const ICDContainerFactory = require('../../icd-v1_5/resources/ContainerFactory');
const OnboardingContainerFactory = require('../../onboarding/resources/ContainerFactory');
const redis = require('redis');
const mockRedis = require('redis-mock');

function ContainerFactory() {
  const container = new inversify.Container();

  ContainerFactory.loadContainerModules(container);
  
  return container;
}


ContainerFactory.loadContainerModules = container => {

  container.bind('FloDetectConfig').toConstantValue({
    floDetectMinimumDaysInstalled: 21,
  });

  if (!ICDContainerFactory.isLoaded(container)) {
    ICDContainerFactory.loadContainerModules(container);
  }

  if (!OnboardingContainerFactory.isLoaded(container)) {
    OnboardingContainerFactory.loadContainerModules(container);
  }

  container.load(serviceContainerModule);
};

module.exports = ContainerFactory;