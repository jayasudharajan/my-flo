const chai = require('chai');
const UserAccountRoleTable = require('../../../../dist/app/services/authorization/UserAccountRoleTable');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const UserAccountRoleSchema = require('../../../../dist/app/models/schemas/userAccountRoleSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ UserAccountRoleSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('UserAccountRoleTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(UserAccountRoleTable).to(UserAccountRoleTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(UserAccountRoleTable);

  tableTestUtils.crudTableTests(table);
});