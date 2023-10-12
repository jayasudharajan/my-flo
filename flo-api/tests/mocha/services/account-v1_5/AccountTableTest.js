const chai = require('chai');
const AccountTable = require('../../../../dist/app/services/account-v1_5/AccountTable');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const AccountSchema = require('../../../../dist/app/models/schemas/accountSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const uuid = require('uuid');
require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ AccountSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('AccountTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(AccountTable.name).to(AccountTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(AccountTable.name);

  tableTestUtils.crudTableTests(table);

  describe('#retrieveByOwnerUserId', function () {
    it('should return multiple records by user id', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = Object.assign(tableTestUtils.generateRecord(table), { owner_user_id: record1.owner_user_id });

      Promise.all([table.create(record1), table.create(record2)])
        .then(() => table.retrieveByOwnerUserId(record1.owner_user_id))
        .then(({ Items }) => Items)
        .should.eventually.deep.include.members([record1, record2])
        .notify(done);
    });
  });

  describe('#retrieveByGroupId', function () {
    it('should return multiple records by group ID', function (done) {
      const record1 = Object.assign(tableTestUtils.generateRecord(table), { group_id: uuid.v4() });
      const record2 = Object.assign(tableTestUtils.generateRecord(table), { group_id: record1.group_id });

      Promise.all([table.create(record1), table.create(record2)])
        .then(() => table.retrieveByGroupId(record1.group_id))
        .then(({ Items }) => Items) 
        .should.eventually.deep.include.members([record1, record2])
        .notify(done);
    });
  });
});