// MicroLeakTestTime Table for DynamoDB

module.exports = {
  TableName : 'MicroLeakTestTime',
  KeySchema: [
    { AttributeName: 'device_id', KeyType: 'HASH' },
    { AttributeName: 'created_at', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'device_id', AttributeType: 'S' },
    { AttributeName: 'created_at', AttributeType: 'S' },
    { AttributeName: 'created_at_device_id', AttributeType: 'S' },
    { AttributeName: 'is_deployed', AttributeType: 'N' }
  ],
  ProvisionedThroughput: {
    ReadCapacityUnits: 1,
    WriteCapacityUnits: 1
  },
  GlobalSecondaryIndexes: [
    {
      IndexName: 'IsDeployedCreatedAtDeviceIdIndex',
      KeySchema: [
        { AttributeName: 'is_deployed', KeyType: 'HASH' },
        { AttributeName: 'created_at_device_id', KeyType: 'RANGE' }
      ],
      Projection: {
        ProjectionType: "ALL"
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    }
  ]
};
