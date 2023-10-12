// Scope Table for DynamoDB

module.exports = {
  TableName : 'Scope',
  KeySchema: [
    { AttributeName: 'scope_name', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'scope_name', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
