const inversify = require('inversify');
const ICDTable = require('../../../../../dist/app/services/icd-v1_5/ICDTable');
const ICDService = require('../../../../../dist/app/services/icd-v1_5/ICDService');
const OnboardingService = require('../../../../../dist/app/services/onboarding/OnboardingService');
const OnboardingController = require('../../../../../dist/app/services/onboarding/OnboardingController');
const OnboardingLogTable = require('../../../../../dist/app/services/onboarding/OnboardingLogTable');
const OnboardingRouter = require('../../../../../dist/app/services/onboarding/routes');
const serviceContainerModule = require('../../../../../dist/app/services/onboarding/container').containerModule;
const AuthMiddleware = require('../../../../../dist/app/services/utils/AuthMiddleware');
const AuthMiddlewareMock = require('../../../utils/AuthMiddlewareMock');
const containerUtil = require('../../../../../dist/util/containerUtil');
const KafkaProducer = require('../../../../../dist/app/services/utils/KafkaProducer');
const redis = require('redis');
const mockRedis = require('redis-mock');
const KafkaProducerMock = require('../../../utils/KafkaProducerMock');

function ContainerFactory(configMock, kafkaProducerMock) {
  const redisClient = mockRedis.createClient();
  const container = new inversify.Container();

  container.bind(ICDTable).to(ICDTable);
  container.bind(OnboardingService).to(OnboardingService);
  container.bind(OnboardingController).to(OnboardingController);
  container.bind(OnboardingRouter).to(OnboardingRouter);
  container.bind(OnboardingLogTable).to(OnboardingLogTable);
  container.bind(ICDService).to(ICDService);
  container.bind(AuthMiddleware).toConstantValue(new AuthMiddlewareMock());
  container.bind(redis.RedisClient).toConstantValue(redisClient);
  container.bind('OnboardingServiceConfig').toConstantValue(configMock);
  container.bind(KafkaProducer).toConstantValue(kafkaProducerMock);
  container.bind('MQTTClient').toConstantValue({
    publish: (topic, message) => {}
  });

  return container;
}

ContainerFactory.loadContainerModules = container => {
  const kafkaProducerMock = new KafkaProducerMock();

  container.bind(KafkaProducer).toConstantValue(kafkaProducerMock);
  container.bind('OnboardingServiceConfig').toConstantValue({
    eventsAckTopic: 'events-ack-v1',
    notificationsKafkaTopic: 'notifications-v2',
    installedAlertId: '5001'
  });


  container.load(serviceContainerModule);
};

ContainerFactory.isLoaded = container => {
  return container.isBound(OnboardingService);
};

module.exports = ContainerFactory;