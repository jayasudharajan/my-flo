const chai = require('chai');
const LocationTable = require('../../../../dist/app/services/location-v1_5/LocationTable');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const LocationSchema = require('../../../../dist/app/models/schemas/locationSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const EncryptionStrategy = require('../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../utils/EncryptionStrategyMock');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ LocationSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('LocationTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(LocationTable.name).to(LocationTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password'));

  // Resolve dependencies
  const table = container.get(LocationTable.name);

  tableTestUtils.crudTableTests(table);

  describe('#retrieveByLocationId', function () {
    it('should return one record by location ID', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(() => table.retrieveByLocationId(record.location_id))
        .then(({ Items }) => Items[0])
        .should.eventually.deep.equal(record)
        .notify(done);
    });
  });

  describe('#retrieveByAccountId', function () {
    it('should return multiple records by account ID', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = Object.assign(tableTestUtils.generateRecord(table), { account_id: record1.account_id });

      table.create(record1)
        .then(() => table.create(record2))
        .then(() => table.retrieveByAccountId(record1.account_id))
        .then(({ Items }) => Items) 
        .should.eventually.deep.include.members([record1, record2])
        .notify(done);
    });
  });
});