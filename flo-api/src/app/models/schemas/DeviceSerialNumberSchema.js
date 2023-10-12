// DeviceSerialNumber Table for DynamoDB

module.exports = {
  TableName : 'DeviceSerialNumber',
  KeySchema: [
    { AttributeName: 'device_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'device_id', AttributeType: 'S' },
    { AttributeName: 'sn', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'SerialNumber',
      KeySchema: [
        { AttributeName: 'sn', KeyType: 'HASH' }
      ],
      Projection: {
        ProjectionType: "ALL"
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
