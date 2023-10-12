// FixtureDetectionLog Table for DynamoDB

module.exports = {
  TableName : 'FixtureDetectionLog',
  KeySchema: [
    { AttributeName: 'request_id', KeyType: 'HASH' },
    { AttributeName: 'created_at', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'request_id', AttributeType: 'S' },
    { AttributeName: 'created_at', AttributeType: 'S' },
    { AttributeName: 'device_id', AttributeType: 'S' },
    { AttributeName: 'start_date_end_date_status', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'start_and_end_date_with_status_index',
      KeySchema: [
        { AttributeName: 'device_id', KeyType: 'HASH' },
        { AttributeName: 'start_date_end_date_status', KeyType: 'RANGE' }
      ],
      Projection: {
        ProjectionType: "ALL"
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    },
    {
      IndexName: 'DeviceIdCreatedAtIndex',
      KeySchema: [
        { AttributeName: 'device_id', KeyType: 'HASH' },
        { AttributeName: 'created_at', KeyType: 'RANGE' }
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

