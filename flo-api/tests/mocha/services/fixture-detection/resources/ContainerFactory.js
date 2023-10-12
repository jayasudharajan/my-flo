const inversify = require('inversify');
const ICDTable = require('../../../../../dist/app/services/icd-v1_5/ICDTable');
const ICDService = require('../../../../../dist/app/services/icd-v1_5/ICDService');
const FixtureDetectionService = require('../../../../../dist/app/services/fixture-detection/FixtureDetectionService');
const FixtureDetectionController = require('../../../../../dist/app/services/fixture-detection/FixtureDetectionController');
const FixtureDetectionRouter = require('../../../../../dist/app/services/fixture-detection/routes');
const FixtureDetectionConfig = require('../../../../../dist/app/services/fixture-detection/FixtureDetectionConfig');
const FixtureDetectionLogTable = require('../../../../../dist/app/services/fixture-detection/FixtureDetectionLogTable');
const KafkaProducer = require('../../../../../dist/app/services/utils/KafkaProducer');
const ACLMiddleware = require('../../../../../dist/app/services/utils/ACLMiddleware');
const ACLMiddlewareMock = require('../../../utils/ACLMiddlewareMock');
const AuthMiddleware = require('../../../../../dist/app/services/utils/AuthMiddleware');
const AuthMiddlewareMock = require('../../../utils/AuthMiddlewareMock');
const redis = require('redis');
const mockRedis = require('redis-mock');

function ContainerFactory(kafkaProducer) {
  const container = new inversify.Container();


  container.bind(ICDTable).to(ICDTable);
  container.bind(ICDService).to(ICDService);
  container.bind(FixtureDetectionService).to(FixtureDetectionService);
  container.bind(FixtureDetectionController).to(FixtureDetectionController);
  container.bind(FixtureDetectionRouter).to(FixtureDetectionRouter);
  container.bind(FixtureDetectionLogTable).to(FixtureDetectionLogTable);


  container.bind(redis.RedisClient).toConstantValue(mockRedis.createClient());
  container.bind(KafkaProducer).toConstantValue(kafkaProducer);
  container.bind(ACLMiddleware).toConstantValue(new ACLMiddlewareMock());
  container.bind(AuthMiddleware).toConstantValue(new AuthMiddlewareMock());


  container.bind(FixtureDetectionConfig).toConstantValue(
  	new (class extends FixtureDetectionConfig {
      fixtureDetectionKafkaTopic() {
        return Promise.resolve('fixture-detection');
      }
  	}));

  return container;
}

module.exports = ContainerFactory;