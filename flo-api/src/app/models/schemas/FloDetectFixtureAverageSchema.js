// FloDetectFixtureAverage Table for DynamoDB

module.exports = {
  TableName : 'FloDetectFixtureAverage',
  KeySchema: [
    { AttributeName: 'device_id', KeyType: 'HASH' },
    { AttributeName: 'duration_in_seconds_start_date', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'device_id', AttributeType: 'S' },
    { AttributeName: 'duration_in_seconds_start_date', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
