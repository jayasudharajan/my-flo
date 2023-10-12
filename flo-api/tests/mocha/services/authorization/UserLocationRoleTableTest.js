const chai = require('chai');
const UserLocationRoleTable = require('../../../../dist/app/services/authorization/UserLocationRoleTable');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const UserLocationRoleSchema = require('../../../../dist/app/models/schemas/userLocationRoleSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ UserLocationRoleSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('UserLocationRoleTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(UserLocationRoleTable).to(UserLocationRoleTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(UserLocationRoleTable);

  tableTestUtils.crudTableTests(table);
});