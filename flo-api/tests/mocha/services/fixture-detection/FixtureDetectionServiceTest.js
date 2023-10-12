const chai = require('chai');
const FixtureDetectionLogTable = require('../../../../dist/app/services/fixture-detection/FixtureDetectionLogTable');
const FixtureDetectionService = require('../../../../dist/app/services/fixture-detection/FixtureDetectionService');
const FixtureDetectionConfig = require('../../../../dist/app/services/fixture-detection/FixtureDetectionConfig');
const TFixturesData = require('../../../../dist/app/services/fixture-detection/models/TFixturesData');
const TFixturesForFeedbackData = require('../../../../dist/app/services/fixture-detection/models/TFixturesForFeedbackData');
const TStatus = require('../../../../dist/app/services/fixture-detection/models/TStatus');
const ICDTable = require('../../../../dist/app/services/icd-v1_5/ICDTable');
const KafkaProducer = require('../../../../dist/app/services/utils/KafkaProducer');
const KafkaProducerMock = require('../../utils/KafkaProducerMock');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const config = require('../../../../dist/config/config');
const tableSchemas = require('./resources/tableSchemas');
const validator = require('validator');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const ContainerFactory = require('./resources/ContainerFactory');
const uuid = require('node-uuid');
const moment = require('moment');
const _ = require('lodash');
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('FixtureDetectionServiceTest', [dynamoDbTestMixin], () => {

  const kafkaProducer = new KafkaProducerMock();
  const container = new ContainerFactory(kafkaProducer);
  const randomDataGenerator = new RandomDataGenerator();

  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const icdTable = container.get(ICDTable);
  const fixtureDetectionLogTable = container.get(FixtureDetectionLogTable);
  const service = container.get(FixtureDetectionService);
  const config = container.get(FixtureDetectionConfig);

  function getFixturesData(device_id) {
    const data = randomDataGenerator.generate(TFixturesData);
    data.device_id = device_id;

    return data;
  }

  function getFixtureDetectionLogEntry(device_id) {
    const data = tableTestUtils.generateRecord(fixtureDetectionLogTable);

    data.status = TStatus.executed;
    data.device_id = device_id;

    return data;
  }



  describe('#logFixtureDetection()', function () {
    it('should save the detected fixtures including a created_at field', function (done) {
      const icd = tableTestUtils.generateRecord(icdTable);
      const data = getFixturesData(icd.device_id);

      icdTable.create(icd).then(() => {
        return service.logFixtureDetection(icd.device_id, data)
      }).then(() => {
        return fixtureDetectionLogTable.scanAll();
      }).then(({ Items: [result] }) => {
        result.should.have.property('created_at');
        result.fixtures.should.have.length(data.fixtures.length)

        _.omit(result, ['created_at', 'fixtures'])
          .should.deep.equal(
            Object.assign(
              _.omit(data, ['fixtures']),
              {
                start_date_end_date_status: `${data.start_date}_${data.end_date}_executed`,
                status: 'executed'
              }
            )
          );

        done();
      }).catch(function (err) {
        done(err);
      });
    });
  });

  describe('#retrieveFixtureDetectionResults()', function () {
    it('should return the detected fixtures by request id', function (done) {
      const icd = tableTestUtils.generateRecord(icdTable);
      const data = getFixtureDetectionLogEntry(icd.device_id);

      Promise.all([
        icdTable.create(icd),
        fixtureDetectionLogTable.create(data)
      ]).then(() => {
        return service.retrieveFixtureDetectionResults(icd.device_id, data.request_id);
      }).then(result => {

        delete result.start_date_end_date_status;

        result.should.deep.equal(data);

        done();
      }).catch(function (err) {
        done(err);
      });
    });
  });

  describe('#retrieveLatestByDeviceId()', function () {
    it('should return the latest detected fixtures by device id', function (done) {
      const icd = tableTestUtils.generateRecord(icdTable);
      const data = getFixtureDetectionLogEntry(icd.device_id);

      data.status = TStatus.executed;

      Promise.all([
        icdTable.create(icd),
        fixtureDetectionLogTable.create(data)
      ]).then(() => {
        return service.retrieveLatestByDeviceId(icd.device_id);
      }).then(result => {

        delete result.start_date_end_date_status;

        result.should.deep.equal(data);

        done();
      }).catch(function (err) {
        done(err);
      });
    });
  });

  describe('#updateFixturesWithFeedback()', function () {
    it('should save the fixture with feedback', function (done) {
      const record = tableTestUtils.generateRecord(fixtureDetectionLogTable);
      const fixtureWithFeedback = randomDataGenerator.generate(TFixturesForFeedbackData);

      fixtureDetectionLogTable.create(record).then(() => {
        return service.updateFixturesWithFeedback(record.request_id, record.created_at, fixtureWithFeedback.fixtures)
      })
        .then(() => {
          fixtureDetectionLogTable.retrieve({ request_id: record.request_id, created_at: record.created_at })
            .then(({ Item }) => {
              Item.should.have.property('status').that.equals(TStatus.feedback_submitted);
              return Item.fixtures;
            })
            .should.eventually.have.length(fixtureWithFeedback.fixtures.length)
            .notify(done);
        })

    })
  });

  describe('#runFixturesDetection()', function () {
    it('should send a kafka message to the detect generator app topic', function (done) {
      const icd = tableTestUtils.generateRecord(icdTable);
      const startDate = moment().toISOString();
      const endDate = moment().add(1, 'days').toISOString();

      icdTable.create(icd).then(() => {
        return Promise.all([
          config.fixtureDetectionKafkaTopic(),
          service.runFixturesDetection(icd.device_id, startDate, endDate)
        ]);
      }).then(([detectGeneratorKafkaTopic, runResult]) => {
        return Promise.all([
          detectGeneratorKafkaTopic,
          runResult,
          fixtureDetectionLogTable.scanAll()
        ]);
      }).then(([detectGeneratorKafkaTopic, runResult, { Items: [log] }]) => {
        const message = kafkaProducer.getSentMessages(detectGeneratorKafkaTopic)[0];

        message.icd_id.should.equal(icd.id);
        message.device_id.should.equal(icd.device_id);
        message.start_date.should.equal(startDate);
        message.end_date.should.equal(endDate);

        validator.isUUID(message.request_id, 4).should.equal(true);
        validator.isUUID(runResult.request_id, 4).should.equal(true);

        log.request_id.should.equal(runResult.request_id);
        log.status.should.equal('sent');

        done();

        return message;
      }).catch(function (err) {
        done(err);
      });
    });
  });
});