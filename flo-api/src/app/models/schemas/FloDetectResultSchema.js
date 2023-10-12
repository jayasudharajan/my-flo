// FloDetectResult Table for DynamoDB

module.exports = {
  TableName : 'FloDetectResult',
  KeySchema: [
    { AttributeName: 'device_id', KeyType: 'HASH' },
    { AttributeName: 'duration_in_seconds_start_date', KeyType: 'RANGE' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'DeviceIdStatusDurationInSecondsStartDate',
      KeySchema: [
        { AttributeName: 'device_id', KeyType: 'HASH' },
        { AttributeName: 'status_duration_in_seconds_start_date', KeyType: 'RANGE' }
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
  AttributeDefinitions: [
    { AttributeName: 'device_id', AttributeType: 'S' },
    { AttributeName: 'duration_in_seconds_start_date', AttributeType: 'S' },
    { AttributeName: 'status_duration_in_seconds_start_date', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};