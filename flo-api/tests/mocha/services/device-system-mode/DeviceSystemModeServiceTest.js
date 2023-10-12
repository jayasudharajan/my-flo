const chai = require('chai');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const config = require('../../../../dist/config/config');
const tableSchemas = require('./resources/tableSchemas');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const ContainerFactory = require('./resources/ContainerFactory');
const DeviceSystemModeService = require('../../../../dist/app/services/device-system-mode/DeviceSystemModeService');
const ICDForcedSystemModeTable = require('../../../../dist/app/services/device-system-mode/ICDForcedSystemModeTable');
const ICDService = require('../../../../dist/app/services/icd-v1_5/ICDService');
const TICD = require('../../../../dist/app/services/icd-v1_5/models/TICD');
const KafkaProducer = require('../../../../dist/app/services/utils/KafkaProducer');
const DirectiveConfig = require('../../../../dist/app/services/directives/DirectiveConfig');
const TaskSchedulerConfig = require('../../../../dist/app/services/task-scheduler/TaskSchedulerConfig');
const _ = require('lodash');

require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('DeviceSystemModeServiceTest', [dynamoDbTestMixin], function () {

  const randomDataGenerator = new RandomDataGenerator();
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(DeviceSystemModeService);
  const kafkaProducer = container.get(KafkaProducer);
  const icdService = container.get(ICDService);
  const directiveConfig = container.get(DirectiveConfig);
  const taskSchedulerConfig = container.get(TaskSchedulerConfig);
  const icdForcedSystemModeTable = container.get(ICDForcedSystemModeTable);

  beforeEach(function (done) {
    const icd = randomDataGenerator.generate(TICD);
    const userId = randomDataGenerator.generate('UUIDv4');
    const appUsed = 0;

    Promise.all([
      directiveConfig.getDirectivesKafkaTopic(),
      taskSchedulerConfig.getTaskSchedulerTopic(),
      taskSchedulerConfig.getTaskCommandTopic(),
      icdService.create(icd),
      kafkaProducer.clear()
    ])
    .then(([directiveTopic, taskSchedulerTopic, taskCommandTopic]) => {
      this.currentTest.directiveTopic = directiveTopic;
      this.currentTest.taskSchedulerTopic = taskSchedulerTopic;
      this.currentTest.taskCommandTopic = taskCommandTopic;
      this.currentTest.icd = icd;
      this.currentTest.metadata = {
        user_id: userId,
        app_used: appUsed
      };
      done();
    })
    .catch(done);
  });

  describe('#sleep', function () {
    it('should send a set-system-mode directive and schedule a wake up', function (done) {
      const icd = this.test.icd;
      const metadata = this.test.metadata;

      service.sleep(icd.id, 2, 120, metadata)
        .then(() => ([
          kafkaProducer.getSentMessages(this.test.directiveTopic),
          kafkaProducer.getSentMessages(this.test.taskSchedulerTopic)
        ]))
        .then(results => _.flatten(results))
        .then(results => {
          return results;
        })
        .should.eventually.have.lengthOf(2)
        .notify(done);
    });

    it('should fail to change the system mode of a device in forced sleep', function (done) {
      const icd = this.test.icd;
      const metadata = this.test.metadata;
      const icdForcedSystemMode = { icd_id: icd.id, system_mode: 5 };

      icdForcedSystemModeTable.create(icdForcedSystemMode)
        .then(() => service.sleep(icd.id, 2, 120, metadata))
        .should.eventually.be.rejected
        .notify(done);
    });
  });

  describe('#enableForcedSleep', function () {
    it('should put the device in forced sleep and cancel any wake up', function (done) {
      const icd = this.test.icd;
      const metadata = this.test.metadata;

      service.enableForcedSleep(icd.id, metadata)
        .then(() => Promise.all([
          service.isInForcedSleep(icd.id),
          kafkaProducer.getSentMessages(this.test.taskCommandTopic).length
        ]))
        .should.eventually.deep.equal([true, 1])
        .notify(done);
    });
  });

  describe('#disableForcedSleep', function () {
    it('should take the device out of forced sleep and cancel any wake up', function (done) {
      const icd = this.test.icd;
      const metadata = this.test.metadata;
      const icdForcedSystemMode = { icd_id: icd.id, system_mode: 5 };

      icdForcedSystemModeTable.create(icdForcedSystemMode)
        .then(() => service.disableForcedSleep(icd.id, metadata))
        .then(() => Promise.all([
          service.isInForcedSleep(icd.id),
          kafkaProducer.getSentMessages(this.test.taskCommandTopic).length
        ]))
        .should.eventually.deep.equal([false, 1])
        .notify(done);
    });
  });

  describe('#setSystemMode', function () {
    it('should sent a set-system-mode directive and cancel any wake up', function (done) {
      const icd = this.test.icd;
      const metadata = this.test.metadata;

      service.setSystemMode(icd.id, 2, metadata)
        .then(() => ([
          kafkaProducer.getSentMessages(this.test.directiveTopic),
          kafkaProducer.getSentMessages(this.test.taskCommandTopic)
        ]))
        .then(results => _.flatten(results))
        .should.eventually.have.lengthOf(2)
        .notify(done);    
    });

    it('should fail to change the system mode of a device in forced sleep', function (done) {
      const icd = this.test.icd;
      const metadata = this.test.metadata;
      const icdForcedSystemMode = { icd_id: icd.id, system_mode: 5 };

      icdForcedSystemModeTable.create(icdForcedSystemMode)
        .then(() => service.setSystemMode(icd.id, 2, metadata))
        .should.eventually.be.rejected
        .notify(done);
    });
  });
});