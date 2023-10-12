const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const testConfig = require('../../../../src/config/config');
const ZITResultTable = require('../../../../dist/app/services/zit-result/ZITResultTable');
const ValidationException = require('../../../../dist/app/models/exceptions/ValidationException');
const assert = require('assert');
const uuid = require('node-uuid');
const clone = require('clone');
const localDynamo = require('local-dynamo');
const TableUtils = require('./../../utils/TableUtils');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const ZITResultSchema = require('../../../../dist/app/models/schemas/ZITResultSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ ZITResultSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('ZITResultTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(ZITResultTable).to(ZITResultTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(ZITResultTable);

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
});