// VPNWhitelist Table for DynamoDB

module.exports = {
  TableName : 'VPNWhitelist',
  KeySchema: [
    { AttributeName: 'device_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'device_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
