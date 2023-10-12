// NotificationToken Table - DynamoDB

module.exports = {
  TableName : 'NotificationToken',
  KeySchema: [
    { AttributeName: "user_id", KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'user_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
    ReadCapacityUnits: 1,
    WriteCapacityUnits: 1
  }
};