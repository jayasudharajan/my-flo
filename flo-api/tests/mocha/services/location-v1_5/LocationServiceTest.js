const _ = require('lodash');
const chai = require('chai');
const LocationTable = require('../../../../dist/app/services/location-v1_5/LocationTable');
const LocationService = require('../../../../dist/app/services/location-v1_5/LocationService');
const authenticationContainerFactory = require('../authentication/resources/ContainerFactory');
const AccountTable = require('../../../../dist/app/services/account-v1_5/AccountTable');
const EncryptionStrategy = require('../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../utils/EncryptionStrategyMock');
const ValidationException = require('../../../../dist/app/models/exceptions/ValidationException');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const LocationSchema = require('../../../../dist/app/models/schemas/locationSchema');
const AuthenticationTableSchemas = require('../authentication/resources/tableSchemas');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const containerUtils = require('../../../../dist/util/containerUtil');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [
    ...AuthenticationTableSchemas,
    LocationSchema,
  ],
  config.aws.dynamodb.prefix
);

describeWithMixins('LocationServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const locationContainer = new inversify.Container();
  locationContainer.bind(LocationTable).to(LocationTable);
  locationContainer.bind(LocationService).to(LocationService);
  locationContainer.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  locationContainer.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password'));

  // Merge with AuthenticationContainerFactory ( also has AccountContainer merged )
  const container = containerUtils.mergeContainers(authenticationContainerFactory(), locationContainer);

  // Resolve dependencies
  const table = container.get(LocationTable);
  const accountTable = container.get(AccountTable);
  const service = container.get(LocationService);

  describe('#create', function () {
    it('should create a new record', function (done) {
      const record = tableTestUtils.generateRecord(table);

      service.create(record)
        .then(() => table.retrieve(tableTestUtils.getRetrieveParamsValues(table, record)))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(record)
        .notify(done);
    });

    it('should fail to create a new record due to validation errors', function (done) {
      const invalidRecord = Object.assign(tableTestUtils.generateRecord(table), { address: 1234 });

      service.create(invalidRecord)
        .then(() => table.retrieve(tableTestUtils.getRetrieveParamsValues(table, invalidRecord)))
        .then(({ Item }) => Item)
        .should.eventually.be.rejectedWith(ValidationException)
        .notify(done);
    });

    it('should create a new record with default values for missing properties', function (done) {
      const partialRecord = _.omit(tableTestUtils.generateRecord(table), ['gallons_per_day_goal']);

      service.create(partialRecord)
        .then(() => table.retrieve(tableTestUtils.getRetrieveParamsValues(table, partialRecord)))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(Object.assign({ gallons_per_day_goal: 240 }, partialRecord))
        .notify(done);
    });

  });

  describe('#createInAccount', function () {
    it('should create a new location record with provided account_id', function(done) {
      const locationRecord = tableTestUtils.generateRecord(table);
      const accountRecord = tableTestUtils.generateRecord(accountTable);
      accountTable.create( accountRecord )
        .then( response => {
          service.createInAccount(Object.assign({}, locationRecord, {account_id: response.id}))
            .should.eventually.have.property("location_id").and.not.be.a("null")
            .notify(done);
        });
    });  
  });

  describe('#retrieve', function () {
    it('should retrieve a record by account and location id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(() => service.retrieve(record.account_id, record.location_id))
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
          return service.patch(record.account_id, record.location_id, updatedRecord);
        })
        .then(function() {
          return table.retrieve(tableTestUtils.getRetrieveParamsValues(table, record));
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
        .then(() => service.remove(record.account_id, record.location_id))
        .then(() => table.retrieve(tableTestUtils.getRetrieveParamsValues(table, record)))
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
        .then(() => service.archive(record.account_id, record.location_id))
        .then(() => table.retrieve(tableTestUtils.getRetrieveParamsValues(table, record)))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(Object.assign({ is_deleted: true }, record))
        .notify(done);
    });
  });

  describe('#retrieveByLocationId', function () {
    it('should return one record by location ID', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(() => service.retrieveByLocationId(record.location_id))
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
        .then(() => service.retrieveByAccountId(record1.account_id))
        .then(({ Items }) => Items) 
        .should.eventually.deep.include.members([record1, record2])
        .notify(done);
    });
  });
});
