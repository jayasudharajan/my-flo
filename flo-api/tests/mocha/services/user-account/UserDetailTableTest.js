const chai = require('chai');
const UserDetailTable = require('../../../../dist/app/services/user-account/UserDetailTable');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const UserDetailSchema = require('../../../../dist/app/models/schemas/userDetailSchema');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const EncryptionStrategy = require('../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../utils/EncryptionStrategyMock');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ UserDetailSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('UserDetailTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = new inversify.Container();
  container.bind(UserDetailTable).to(UserDetailTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('super secret password'));

  // Resolve dependencies
  const table = container.get(UserDetailTable);

  tableTestUtils.crudTableTests(table);
});