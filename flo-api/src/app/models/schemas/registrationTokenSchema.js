// RegistrationToken Table for DynamoDB

module.exports = {
  TableName : 'RegistrationToken',
  KeySchema: [
    { AttributeName: 'token1', KeyType: 'HASH' },
    { AttributeName: 'token2', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'token1', AttributeType: 'S' },
    { AttributeName: 'token2', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
