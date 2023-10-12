const chai = require('chai');
const ICDTable = require('../../../../dist/app/services/icd-v1_5/ICDTable');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const ICDSchema = require('../../../../dist/app/models/schemas/icdSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const redis = require('redis');
const mockRedis = require('redis-mock');
require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ ICDSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('ICDTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const redisClient = mockRedis.createClient();
  const container = new inversify.Container();
  container.bind(ICDTable.name).to(ICDTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  container.bind(redis.RedisClient).toConstantValue(redisClient);

  // Resolve dependencies
  const table = container.get(ICDTable.name);

  tableTestUtils.crudTableTests(table);

  describe('#retrieveByDeviceId', function () {
    it('should return one record by device id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(() => table.retrieveByDeviceId(record.device_id))
        .then(({ Items }) => Items[0])
        .should.eventually.deep.equal(record)
        .notify(done);
    });
  });

  describe('#retrieveByLocationId', function () {
    it('should return multiple records by location ID', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = Object.assign(tableTestUtils.generateRecord(table), { location_id: record1.location_id });

      table.create(record1)
        .then(() => table.create(record2))
        .then(() => table.retrieveByLocationId(record1.location_id))
        .then(({ Items }) => Items) 
        .should.eventually.deep.include.members([record1, record2])
        .notify(done);
    });
  });
});