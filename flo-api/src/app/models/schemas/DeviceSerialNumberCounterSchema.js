// DeviceSerialNumberCounter Table for DynamoDB

module.exports = {
  TableName : 'DeviceSerialNumberCounter',
  KeySchema: [
    { AttributeName: 'date', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'date', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
