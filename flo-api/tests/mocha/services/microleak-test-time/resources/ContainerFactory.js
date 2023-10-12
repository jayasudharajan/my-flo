const inversify = require('inversify');
const LocationContainerFactory = require('../../location-v1_5/resources/ContainerFactory');
const MicroLeakTestTimeService = require('../../../../../dist/app/services/microleak-test-time/MicroLeakTestTimeService');
const MicroLeakTestTimeController = require('../../../../../dist/app/services/microleak-test-time/MicroLeakTestTimeController');
const MicroLeakTestTimeRouter = require('../../../../../dist/app/services/microleak-test-time/routes');
const DirectiveConfig = require('../../../../../dist/app/services/directives/DirectiveConfig');
const MicroLeakTestTimeTable = require('../../../../../dist/app/services/microleak-test-time/MicroLeakTestTimeTable');
const ICDTable = require('../../../../../dist/app/services/icd-v1_5/ICDTable');
const ICDService = require('../../../../../dist/app/services/icd-v1_5/ICDService');
const DirectiveLogTable = require('../../../../../dist/app/models/DirectiveLogTable');
const DirectiveService = require('../../../../../dist/app/services/directives/DirectiveService');
const KafkaProducer = require('../../../../../dist/app/services/utils/KafkaProducer');
const ACLMiddleware = require('../../../../../dist/app/services/utils/ACLMiddleware');
const ACLMiddlewareMock = require('../../../utils/ACLMiddlewareMock');
const AuthMiddleware = require('../../../../../dist/app/services/utils/AuthMiddleware');
const AuthMiddlewareMock = require('../../../utils/AuthMiddlewareMock');
const redis = require('redis');
const mockRedis = require('redis-mock');

const containerUtil = require('../../../../../dist/util/containerUtil');

function ContainerFactory(kafkaProducer) {
  const container = new inversify.Container();

  container.bind(ICDTable).to(ICDTable);
  container.bind(DirectiveLogTable).to(DirectiveLogTable);
  container.bind(ICDService).to(ICDService);
  container.bind(DirectiveService).to(DirectiveService);
  container.bind(MicroLeakTestTimeService).to(MicroLeakTestTimeService);
  container.bind(MicroLeakTestTimeController).to(MicroLeakTestTimeController);
  container.bind(MicroLeakTestTimeRouter).to(MicroLeakTestTimeRouter);
  container.bind(MicroLeakTestTimeTable).to(MicroLeakTestTimeTable);


  container.bind(KafkaProducer).toConstantValue(kafkaProducer);
  container.bind(ACLMiddleware).toConstantValue(new ACLMiddlewareMock());
  container.bind(AuthMiddleware).toConstantValue(new AuthMiddlewareMock());
  container.bind(redis.RedisClient).toConstantValue(mockRedis.createClient());


  container.bind(DirectiveConfig).toConstantValue(
  	new (class extends DirectiveConfig {
      getDirectivesKafkaTopic() {
        return Promise.resolve('directives-topic');
      }
  	}));

  return [
    LocationContainerFactory()
  ].reduce(containerUtil.mergeContainers, container);
}

module.exports = ContainerFactory;