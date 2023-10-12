// KernelVersion Table - DynamoDB

module.exports = {
  TableName : 'KernelVersion',
  KeySchema: [
      { AttributeName: 'model', KeyType: 'HASH' },
      { AttributeName: 'version', KeyType: 'RANGE' },
  ],
  AttributeDefinitions: [
      { AttributeName: 'model', AttributeType: 'S' },
      { AttributeName: 'version', AttributeType: 'S' },
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
