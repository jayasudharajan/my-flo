const chai = require('chai');
const ICDTable = require('../../../../dist/app/models/ICDTable');
const ZITResultTable = require('../../../../dist/app/services/zit-result/ZITResultTable');
const ICDService = require('../../../../dist/app/services/icd/ICDService');
const ZITResultService = require('../../../../dist/app/services/zit-result/ZITResultService');
const ValidationException = require('../../../../dist/app/models/exceptions/ValidationException');
const uuid = require('node-uuid');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const ZITResultSchema = require('../../../../dist/app/models/schemas/ZITResultSchema');
const ICDSchema = require('../../../../dist/app/models/schemas/icdSchema');
const validator = require('validator');
const redis = require('redis');
const mockRedis = require('redis-mock');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ ZITResultSchema, ICDSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('ZITResultServiceTest', [ dynamoDbTestMixin ], () => {
  const redisClient = mockRedis.createClient();

  // Declare bindings
  const container = new inversify.Container();

  container.bind(ICDTable).to(ICDTable);
  container.bind(ICDService).to(ICDService);
  container.bind(ZITResultTable).to(ZITResultTable);
  container.bind(ZITResultService).to(ZITResultService);
  container.bind(redis.RedisClient).toConstantValue(redisClient);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const icdTable = container.get(ICDTable);
  const zitResultTable =  container.get(ZITResultTable);
  const zitResultService = container.get(ZITResultService);

  describe('#createByDeviceId()', function() {
    it('should create successfully a record', function (done) {
      const icd = getNewICD();
      const zitResult = getNewZitResult(icd.device_id);

      icdTable.create(icd)
        .then(function() {
          return zitResultService.createByDeviceId(icd.device_id, zitResult.test, zitResult.data);
        })
        .then(function() {
          return zitResultTable.retrieve({ icd_id: icd.id, round_id: zitResult.data.round_id });
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item.event;
        })
        .should.eventually.equal(zitResult.data.event).notify(done);
    });

    it('should not create a record because validation errors', function (done) {
      const icd = getNewICD();
      const zitResult = getNewZitResult(icd.device_id);

      zitResult.data.round_id = 2;

      icdTable.create(icd)
        .then(function() {
          return zitResultService.createByDeviceId(icd.device_id, zitResult.test, zitResult.data);
        })
        .should.be.rejectedWith(ValidationException)
        .and.notify(done);
    });
  });

  describe('#retrieveByIcdId()', function() {
    it('should return a record by icd id', function (done) {
      const icd = getNewICD();
      const zitResult = getNewRecord(icd.id);

      icdTable.create(icd)
        .then(function() {
          return zitResultTable.create(zitResult);
        })
        .then(function() {
          return zitResultService.retrieveByIcdId(icd.id);
        })
        .then(function(result) {
          return result[0];
        })
        .should.eventually.deep.equal(zitResult).notify(done);
    });
  });

  describe('#retrieveByDeviceId()', function() {
    it('should return a record by device id', function (done) {
      const icd = getNewICD();
      const zitResult = getNewRecord(icd.id);

      icdTable.create(icd)
        .then(function() {
          return zitResultTable.create(zitResult);
        })
        .then(function() {
          return zitResultService.retrieveByDeviceId(icd.device_id);
        })
        .then(function(result) {
          return result[0];
        }).should.eventually.deep.equal(zitResult).notify(done);
    });
  });

  function getNewICD() {
    const randomDataGenerator = new RandomDataGenerator();

    return {
      id: uuid.v4(),
      location_id: uuid.v4(),
      is_paired: true,
      device_id: randomDataGenerator.generate('DeviceId')
    };
  }

  function getNewZitResult(device_id) {
    return {
      id: uuid.v4(),
      device_id: device_id,
      test: "mvrzit",
      time: "now",
      ack_topic: "my-topic",
      data: {
        round_id: uuid.v4(),
        started_at: new Date().getTime(),
        start_pressure: 0.9,
        end_pressure: 0.9,
        delta_pressure: 0,
        leak_type: -1,
        event: uuid.v4()
      }
    };
  }

  function getNewRecord(icd_id) {
    var date = new Date();

    return {
      icd_id: icd_id,
      round_id: uuid.v4(),
      delta_pressure: 0,
      start_pressure: 0.1,
      end_pressure: 0.2,
      started_at: date.toISOString(),
      ended_at: date.toISOString(),
      event: "end",
      leak_type: 1,
      test: "zit"
    };
  }
});