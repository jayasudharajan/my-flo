const chai = require('chai');
const UltimaVersionTable = require('../../../../dist/app/services/ultima-version/UltimaVersionTable');
const ValidationException = require('../../../../dist/app/models/exceptions/ValidationException');
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

describeWithMixins('UltimaVersionTable', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(UltimaVersionTable).to(UltimaVersionTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(UltimaVersionTable);

  tableTestUtils.crudTableTests(table);

  describe('#retrieveByModel()', function() {
    it('should return one record by model', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(function() {
          return table.retrieveByModel({ model: record.model });
        })
        .then(function(returnedRecord) {
          return returnedRecord[0].model;
        })
        .should.eventually.deep.equal(record.model).notify(done);
    });
  });
});