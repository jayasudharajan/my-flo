const chai = require('chai');
const InsuranceLetterRequestLogTable = require('../../../../dist/app/services/insurance-letter/InsuranceLetterRequestLogTable');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const InsuranceLetterRequestLogSchema = require('../../../../dist/app/models/schemas/InsuranceLetterRequestLogSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ InsuranceLetterRequestLogSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('InsuranceLetterRequestLogTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(InsuranceLetterRequestLogTable).to(InsuranceLetterRequestLogTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(InsuranceLetterRequestLogTable);

  tableTestUtils.crudTableTests(table);
});