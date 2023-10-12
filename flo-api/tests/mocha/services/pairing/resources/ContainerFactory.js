const inversify = require('inversify');
const pairingContainerModule = require('../../../../../dist/app/services/pairing/container').containerModule;
const icdContainerModule = require('../../../../../dist/app/services/icd-v1_5/container').containerModule;
const authorizationContainerModule = require('../../../../../dist/app/services/authorization/container').containerModule;
const stockICDContainerModule = require('../../../../../dist/app/services/stock-icd/container').containerModule;
const systemUserContainerModule = require('../../../../../dist/app/services/system-user/container').containerModule;
const MQTTCertService = require('../../../../../dist/app/services/mqtt-cert/MQTTCertService');
const ACLService = require('../../../../../dist/app/services/utils/ACLService');
const ACLServiceMock = require('../../../utils/ACLServiceMock');
const kafkaContainerModule = require('../../container_modules/kafka');
const redisContainerModule = require('../../container_modules/redis');
const AWS = require('aws-sdk');
const AWSMock = require('mock-aws-s3');
const EncryptionStrategy = require('../../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../../utils/EncryptionStrategyMock');
const DeviceSystemModeContainerFactory = require('../../device-system-mode/resources/ContainerFactory');
const Logger = require('../../../../../dist/app/services/utils/Logger');

function ContainerFactory() {
  const container = new inversify.Container();

  container.load(kafkaContainerModule, redisContainerModule);
  container.bind(Logger).toConstantValue(new Logger());
  container.bind(MQTTCertService).toConstantValue({
    retrieveCAFile(floCaVersion) { return new Promise(resolve => resolve(Buffer.from('foobarbazquuxquuz'))); }
  });
  container.bind(ACLService).toConstantValue(new ACLServiceMock());
  container.bind(AWS.S3).toConstantValue(AWSMock.S3({
    params: { }
  }));
  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('foo'));

  DeviceSystemModeContainerFactory.loadContainerModules(container);

  container.bind('PESService').toConstantValue({
    addDevice: () => Promise.resolve()
  });

  container.load(pairingContainerModule, icdContainerModule, authorizationContainerModule, stockICDContainerModule, systemUserContainerModule);

  return container;
}

module.exports = ContainerFactory;
