// TimeZone Table for DynamoDB

module.exports = {
  TableName : 'TimeZone',
  KeySchema: [
    { AttributeName: 'tz', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'tz', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
