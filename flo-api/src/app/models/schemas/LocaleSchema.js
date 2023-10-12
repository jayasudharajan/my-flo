// Locale Table for DynamoDB

module.exports = {
  TableName : 'Locale',
  KeySchema: [
    { AttributeName: 'locale', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'locale', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
