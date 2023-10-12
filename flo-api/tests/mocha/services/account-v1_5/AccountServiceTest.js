const _ = require('lodash');
const chai = require('chai');
const AccountTable = require('../../../../dist/app/services/account-v1_5/AccountTable');
const AccountService = require('../../../../dist/app/services/account-v1_5/AccountService');
const LocationTable = require('../../../../dist/app/services/location-v1_5/LocationTable');
const LocationService = require('../../../../dist/app/services/location-v1_5/LocationService');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const AccountSchema = require('../../../../dist/app/models/schemas/accountSchema');
const LocationSchema = require('../../../../dist/app/models/schemas/locationSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const EncryptionStrategy = require('../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../utils/EncryptionStrategyMock');
const ValidationException = require('../../../../dist/app/models/exceptions/ValidationException');
const uuid = require('uuid');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ AccountSchema, LocationSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('AccountServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(AccountTable).to(AccountTable);
  container.bind(AccountService).to(AccountService);
  container.bind(LocationTable).to(LocationTable);
  container.bind(LocationService).to(LocationService);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password'));

  // Resolve dependencies
  const table = container.get(AccountTable);
  const locationTable = container.get(LocationTable);
  const service = container.get(AccountService);

  describe('#create', function () {
    it('should create a new record', function (done) {
      const record = tableTestUtils.generateRecord(table);

      service.create(record)
        .then(() => table.retrieve({ id: record.id }))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(record)
        .notify(done);
    });

    it('should fail to create a new record due to validation errors', function (done) {
      const invalidRecord = _.omit(tableTestUtils.generateRecord(table), ['owner_user_id']);

      service.create(invalidRecord)
        .then(() => table.retrieve({ id: invalidRecord.id }))
        .then(({ Item }) => Item)
        .should.eventually.be.rejectedWith(ValidationException)
        .notify(done);
    });

  });

  describe('#retrieve', function () {
    it('should retrieve a record by id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(() => service.retrieve(record.id))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(record)
        .notify(done);
    });
  });

  describe('#update', function () {
    it('should update successfully a record', function (done) {
      const record = tableTestUtils.generateRecord(table);
      const updatedRecord = tableTestUtils.getUpdatedRecord(table, record);

      table.create(record)
        .then(function() {
          return service.update(updatedRecord);
        })
        .then(function() {
          return table.retrieve(tableTestUtils.getRetrieveParamsValues(table, record));
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item;
        })
        .should.eventually.deep.equal(updatedRecord).notify(done);
    });

    it('should not update a record because validation errors', function (done) {
      const record = tableTestUtils.generateRecord(table);
      const updatedRecord = tableTestUtils.generateAnInvalidRecord(table, record);

      table.create(record)
        .then(function() {
          return service.update(updatedRecord);
        })
        .should.be.rejectedWith(ValidationException)
        .and.notify(done);
    });
  });

  describe('#patch', function() {
    it('should patch successfully a record', function (done) {
      const record = tableTestUtils.generateRecord(table);
      const updatedRecord = tableTestUtils.getUpdatedRecord(table, record);

      table.create(record)
        .then(function() {
          return service.patch(record.id, updatedRecord);
        })
        .then(function() {
          return table.retrieve({ id: record.id });
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item;
        })
        .should.eventually.deep.equal(updatedRecord).notify(done);
    });
  });

  describe('#remove', function () {
    it('should remove a record', function (done) {
      const record = tableTestUtils.generateRecord(table);
      const updatedRecord = tableTestUtils.getUpdatedRecord(table, record);

      table.create(record)
        .then(() => service.remove(record.id))
        .then(() => table.retrieve({ id: record.id }))
        .then(({ Item }) => Item)
        .should.eventually.not.exist
        .notify(done);
    });
  });

  describe('#archive', function () {
    it('should archive a record', function (done) {
      const record = tableTestUtils.generateRecord(table);
      const updatedRecord = tableTestUtils.getUpdatedRecord(table, record);

      table.create(record)
        .then(() => service.archive(record.id))
        .then(() => table.retrieve({ id: record.id }))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(Object.assign({ is_deleted: true }, record))
        .notify(done);
    });
  });

  describe('#retrieveByOwnerUserId', function () {
    it('should return multiple records by user id', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = Object.assign(tableTestUtils.generateRecord(table), { owner_user_id: record1.owner_user_id });

      Promise.all([table.create(record1), table.create(record2)])
        .then(() => service.retrieveByOwnerUserId(record1.owner_user_id))
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
        .then(() => service.retrieveByGroupId(record1.group_id))
        .then(({ Items }) => Items) 
        .should.eventually.deep.include.members([record1, record2])
        .notify(done);
    });
  });

});
