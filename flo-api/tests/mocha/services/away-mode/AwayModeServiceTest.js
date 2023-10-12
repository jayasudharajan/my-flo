const _ = require('lodash');
const chai = require('chai');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const ContainerFactory = require('./resources/ContainerFactory');
const AwayModeService = require('../../../../dist/app/services/away-mode/AwayModeService');
const tableSchemas = require('./resources/tableSchemas');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const ICDService = require('../../../../dist/app/services/icd-v1_5/ICDService');
const TICD = require('../../../../dist/app/services/icd-v1_5/models/TICD');
const TIrrigationTimes = require('../../../../dist/app/services/away-mode/models/TIrrigationTimes');
const KafkaProducer = require('../../../../dist/app/services/utils/KafkaProducer');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);
const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('AwayModeServiceTest', [dynamoDbTestMixin], () => {
  // Declare bindings
  const container = ContainerFactory(randomDataGenerator);

  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(AwayModeService);
  const kafkaProducer = container.get(KafkaProducer);
  const icdService = container.get(ICDService);

  beforeEach(function (done) {
    const icd = randomDataGenerator.generate(TICD);

    Promise.all([
      icdService.create(icd),
      kafkaProducer.clear()
    ])
    .then(() => {
      this.currentTest.icd = icd;
      done();
    })
    .catch(done);
  });

  describe('#retrieveIrrigationSchedule', function () {
    it('should return an irrigation schedule', function (done) {
      const icd = this.test.icd;

      service.retrieveIrrigationSchedule(icd.id)
        .should.eventually.have.keys(['device_id', 'times', 'status'])
        .notify(done);
    });
  });

  describe('#retrieveAwayModeState', function () {
    it('should return false if no record exists', function (done) {
      const icd = this.test.icd;

      service.retrieveAwayModeState(icd.id)
        .should.eventually.have.property('is_enabled', false)
        .notify(done);
    });
  });

  describe('#enableDeviceAwayMode', function () {
    it('should send a directive to enable away mode and log the state', function (done) {
      const icd = this.test.icd;
      const irrigationTimes = Array(3).fill(null)
        .map(() => ([
          randomDataGenerator.generate('HourMinuteSeconds'), 
          randomDataGenerator.generate('HourMinuteSeconds')
        ]));

      service.enableDeviceAwayMode(icd.id, irrigationTimes, randomDataGenerator.generate('UUIDv4'), 1)
        .then(() => service.retrieveAwayModeState(icd.id))
        .then(state => {
          const directiveData = kafkaProducer.getSentMessages()[0].directive.data;

          directiveData.should.have.property('enabled', true);
          directiveData.should.include.key('schedule');

          state.should.include.property('is_enabled', true);

          done();
        })
        .catch(done);
    });
  });

  describe('#disableDeviceAwayMode', function () {
    it('should send a directive to disable away mode and log the state', function (done) {
      const icd = this.test.icd;

      service.disableDeviceAwayMode(icd.id, randomDataGenerator.generate('UUIDv4'), 1)
        .then(() => service.retrieveAwayModeState(icd.id))
        .then(state => {
          const directiveData = kafkaProducer.getSentMessages()[0].directive.data;

          directiveData.should.have.property('enabled', false);
          directiveData.should.not.include.key('schedule');

          state.should.include.property('is_enabled', false);

          done();
        })
        .catch(done);
    });
  });
});