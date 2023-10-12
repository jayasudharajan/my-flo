const AWS = require('aws-sdk');
const inversify = require('inversify');
const mockRedis = require('redis-mock');
const redis = require('redis');
const sinon = require('sinon');

const ClientService = require('../../../../../dist/app/services/client/ClientService');
const ICDContainerFactory = require('../../icd-v1_5/resources/ContainerFactory');
const InfoService = require('../../../../../dist/app/services/info/InfoService');
const DeviceStateService = require('../../../../../dist/app/services/device-state/DeviceStateService');
const DeviceStateLogTable = require('../../../../../dist/app/services/device-state/DeviceStateLogTable');
const Logger = require('../../../../../dist/app/services/utils/Logger');
const config = require('../../../../../dist/config/config');
const containerUtil = require('../../../../../dist/util/containerUtil');

function ContainerFactory() {
  const container = new inversify.Container();
  const s3Stub = {
    getObject: sinon.stub()
  };

  const infoServiceStub = {
    users: {
      retrieveAll: sinon.stub(),
      retrieveByUserId: sinon.stub()
    },
    icds: {
      retrieveByICDId: sinon.stub()
    }
  };

  const clientServiceStub = {
    retrieveClientsByUserId: sinon.stub()
  };

  const loggerStub = {
    info: sinon.stub(),
    warn: sinon.stub()
  };

  config.googleHomeTokenProviderBucket = 's3-token-bucket';
  config.googleHomeTokenProviderKey = 's3-token-key'
  config.clientIds = 'GoogleSmartHome:1234';

  container.bind(DeviceStateLogTable).to(DeviceStateLogTable);
  container.bind(DeviceStateService).to(DeviceStateService);
  container.bind(InfoService).toConstantValue(infoServiceStub)
  container.bind(ClientService).toConstantValue(clientServiceStub)
  container.bind(redis.RedisClient).toConstantValue(mockRedis.createClient());
  container.bind(AWS.S3).toConstantValue(s3Stub);
  container.bind('SmartHome').toConstantValue(sinon.stub());
  container.bind('RandomUuid').toConstantValue(sinon.stub());
  container.bind(Logger).toConstantValue(loggerStub);

  return [
    ICDContainerFactory()
  ].reduce(containerUtil.mergeContainers, container);
}

module.exports = ContainerFactory;