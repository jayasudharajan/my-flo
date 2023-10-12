// Client Table for DynamoDB

module.exports = {
  TableName : 'Client',
  KeySchema: [
    { AttributeName: 'client_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'client_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
