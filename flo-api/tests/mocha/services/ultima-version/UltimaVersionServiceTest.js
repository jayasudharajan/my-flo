const chai = require('chai');
const UltimaVersionTable = require('../../../../dist/app/services/ultima-version/UltimaVersionTable');
const UltimaVersionService = require('../../../../dist/app/services/ultima-version/UltimaVersionService');
const assert = require('assert');
const uuid = require('node-uuid');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const UltimaVersionSchema = require('../../../../dist/app/models/schemas/ultimaVersionSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ UltimaVersionSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('UltimaVersionService', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();

  container.bind(UltimaVersionTable).to(UltimaVersionTable);
  container.bind(UltimaVersionService).to(UltimaVersionService);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(UltimaVersionTable);
  const service = container.get(UltimaVersionService);

  describe('#queryPartition()', function() {
    it('should return the partition by model', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = tableTestUtils.generateRecord(table);
      const record3 = tableTestUtils.generateRecord(table);

      record2.model = record1.model;

      Promise.all([
        table.create(record1),
        table.create(record2),
        table.create(record3)
      ]).then(function() {
          return service.retrieveByModel(record1.model);
        })
        .then(function(result) {
          return result.length;
        })
        .should.eventually.equal(2)
        .notify(done);
    });
  });

  describe('#scan()', function() {
    it('should return all the records', function (done) {
      const record1 = tableTestUtils.generateRecord(table);
      const record2 = tableTestUtils.generateRecord(table);
      const record3 = tableTestUtils.generateRecord(table);

      Promise.all([
        table.create(record1),
        table.create(record2),
        table.create(record3)
      ]).then(function() {
          return service.scan();
        })
        .then(function(result) {
          return result.Items;
        })
        .should.eventually.to.deep.include.members([record1, record2, record3])
        .notify(done);
    });
  });
});