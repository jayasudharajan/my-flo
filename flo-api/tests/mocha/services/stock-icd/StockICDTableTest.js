const chai = require('chai');
const StockICDTable = require('../../../../dist/app/services/stock-icd/StockICDTable');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const StockICDSchema = require('../../../../dist/app/models/schemas/stockICDSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
require("reflect-metadata");
const EncryptionStrategy = require('../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../utils/EncryptionStrategyMock');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ StockICDSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('StockICDTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(StockICDTable.name).to(StockICDTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('secret'));

  // Resolve dependencies
  const table = container.get(StockICDTable.name);

  tableTestUtils.crudTableTests(table);

  describe('#retrieveByDeviceId()', function() {
    it('should return one record by device id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(function() {
          return table.retrieveByDeviceId({ device_id: record.device_id });
        })
        .then(function(returnedRecord) {
          return returnedRecord.Items[0].device_id;
        })
        .should.eventually.deep.equal(record.device_id).notify(done);
    });
  });
});