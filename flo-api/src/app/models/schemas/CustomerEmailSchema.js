// CustomerEmail Table for DynamoDB

module.exports = {
  TableName : 'CustomerEmail',
  KeySchema: [
    { AttributeName: 'email_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'email_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
