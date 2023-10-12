const _ = require('lodash');
const chai = require('chai');
const UserTable = require('../../../../dist/app/services/user-account/UserTable');
const EmailAlreadyInUseException = require('../../../../dist/app/services/user-account/models/exceptions/EmailAlreadyInUseException');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const UserSchema = require('../../../../dist/app/models/schemas/userSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const EncryptionStrategy = require('../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../utils/EncryptionStrategyMock');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ UserSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('UserTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(UserTable).to(UserTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password'));

  // Resolve dependencies
  const table = container.get(UserTable);
  const userCrudTest = (expectedRecord, promise, done) => {
      return promise
        .then(user => _.omit(user, ['password']))
        .should.eventually.deep.equal(_.omit(expectedRecord, ['password']))
        .notify(done);
  };
  tableTestUtils.crudTableTests(table, {
    testCreate: userCrudTest,
    testUpdate: userCrudTest,
    testPatch: userCrudTest
  });

  describe('#retrieveByEmail', function () {
    it('#should retrieve one record by email', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(() => table.retrieveByEmail(record.email))
        .then(({ Items }) => Items[0])
        .should.eventually.deep.equal(record)
        .notify(done);
    });
  });

  describe('#create', function () {
    it('#should fail to create a record with a duplicate email', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = Object.assign(
        tableTestUtils.generateRecord(table), 
        { email: record1.email }
      );

      table.create(record1)
        .then(() => table.create(record2))
        .should.eventually.be.rejectedWith(EmailAlreadyInUseException)
        .notify(done);
    });
  });

  describe('#update', function () {
    it('#should fail to update a record with a duplicate email', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = tableTestUtils.generateRecord(table);

      Promise.all([
        table.create(record1),
        table.create(record2)
      ])
        .then(() => table.update(Object.assign({}, record2, { email: record1.email })))
        .should.eventually.be.rejectedWith(EmailAlreadyInUseException)
        .notify(done);
    });
  });


  describe('#patch', function () {
    it('#should fail to patch a record with a duplicate email', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = tableTestUtils.generateRecord(table);

      Promise.all([
        table.create(record1),
        table.create(record2)
      ])
        .then(() => table.patch({ id: record2.id }, { email: record1.email }))
        .should.eventually.be.rejectedWith(EmailAlreadyInUseException)
        .notify(done);
    });
  });
});