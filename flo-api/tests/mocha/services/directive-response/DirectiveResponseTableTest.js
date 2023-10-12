const chai = require('chai');
const DirectiveResponseTable = require('../../../../dist/app/services/directive-response/DirectiveResponseTable');
const TableUtils = require('./../../utils/TableUtils');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const DirectiveResponseLogSchema = require('../../../../dist/app/models/schemas/DirectiveResponseLogSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ DirectiveResponseLogSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('DirectiveResponseTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(DirectiveResponseTable).to(DirectiveResponseTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table =  container.get(DirectiveResponseTable);

  tableTestUtils.crudTableTests(table);

  describe('#retrieveByIcdId()', function() {
    it('should return one record by icd id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(function(result) {
          return table.retrieveByIcdId({ icd_id: record.icd_id });
        })
        .then(function(returnedRecords) {
          return returnedRecords[0];
        })
        .should.eventually.deep.equal(record).notify(done);
    });
  });
}, 50000);


