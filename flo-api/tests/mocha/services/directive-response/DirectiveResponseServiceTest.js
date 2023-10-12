const chai = require('chai');
const ICDTable = require('../../../../dist/app/models/ICDTable');
const DirectiveResponseTable = require('../../../../dist/app/services/directive-response/DirectiveResponseTable');
const ICDService = require('../../../../dist/app/services/icd/ICDService');
const DirectiveResponseService = require('../../../../dist/app/services/directive-response/DirectiveResponseService');
const TDirectiveResponseLog = require('../../../../dist/app/services/directive-response/models/TDirectiveResponseLog');
const ValidationException = require('../../../../dist/app/models/exceptions/ValidationException');
const assert = require('assert');
const uuid = require('node-uuid');
const clone = require('clone');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const config = require('../../../../dist/config/config');
const DirectiveResponseLogSchema = require('../../../../dist/app/models/schemas/DirectiveResponseLogSchema');
const ICDSchema = require('../../../../dist/app/models/schemas/icdSchema');
const redis = require('redis');
const mockRedis = require('redis-mock');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ DirectiveResponseLogSchema, ICDSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('DirectiveResponseServiceTest', [ dynamoDbTestMixin ], () => {
  const redisClient = mockRedis.createClient();
  const randomDataGenerator = new RandomDataGenerator();

  // Declare bindings
  const container = new inversify.Container();

  container.bind(ICDTable).to(ICDTable);
  container.bind(ICDService).to(ICDService);
  container.bind(DirectiveResponseTable).to(DirectiveResponseTable);
  container.bind(DirectiveResponseService).to(DirectiveResponseService);
  container.bind(redis.RedisClient).toConstantValue(redisClient);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const icdTable = container.get(ICDTable);
  const directiveResponseTable =  container.get(DirectiveResponseTable);
  const directiveResponseService = container.get(DirectiveResponseService);

  describe('#createByDeviceId()', function() {
    // it('should create successfully a record', function (done) {
    //   const icd = getNewICD();
    //   const directiveResponse = getNewDirectiveResponseRecord(icd.device_id, icd.id);

    //   icdTable.create(icd)
    //     .then(function() {
    //       return directiveResponseService.logDirectiveResponse(icd.device_id, directiveResponse);
    //     })
    //     .then(function() {
    //       return directiveResponseTable.retrieve(
    //         { icd_id: directiveResponse.icd_id, created_at: directiveResponse.created_at }
    //       );
    //     })
    //     .then(function(returnedRecord) {
    //       return returnedRecord.Item.directive_id;
    //     })
    //     .should.eventually.equal(directiveResponse.directive_id).notify(done);
    // });

    it('should not create a record because validation errors', function (done) {
      const icd = getNewICD();
      const directiveResponse = getNewDirectiveResponseRecord(icd.device_id, icd.id);

      delete directiveResponse.id;

      icdTable.create(icd)
        .then(function() {
          return directiveResponseService.logDirectiveResponse(icd.device_id, directiveResponse);
        })
        .should.be.rejectedWith(ValidationException)
        .and.notify(done);
    });
  });
}, 500000);

function getNewICD() {
  const randomDataGenerator = new RandomDataGenerator();

  return {
    id: uuid.v4(),
    location_id: uuid.v4(),
    is_paired: true,
    device_id: randomDataGenerator.generate('DeviceId')
  };
}

function getNewDirectiveResponseRecord(deviceId, icd_id) {
  const randomDataGenerator = new RandomDataGenerator();
  const record = randomDataGenerator.generate(
    TDirectiveResponseLog,
    { maybeIgnored: true }
  );

  record.icd_id = icd_id;
  record.device_id = deviceId;

  return record;
}