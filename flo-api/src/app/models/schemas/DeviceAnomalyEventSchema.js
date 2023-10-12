// DeviceAnomalyEvent Table for DynamoDB

module.exports = {
  TableName: 'DeviceAnomalyEvent',
  KeySchema: [
    {AttributeName: 'device_id', KeyType: 'HASH'},
    {AttributeName: 'time', KeyType: 'RANGE'}
  ],
  AttributeDefinitions: [
    {AttributeName: 'device_id', AttributeType: 'S'},
    {AttributeName: 'time', AttributeType: 'S'},
    {AttributeName: 'time_device_id', AttributeType: 'S'},
    {AttributeName: 'type', AttributeType: 'N'}
  ],
  ProvisionedThroughput: {
    ReadCapacityUnits: 1,
    WriteCapacityUnits: 1
  },
  GlobalSecondaryIndexes: [
    {
      IndexName: "DeviceAnomalyEventTypeTimeIndex",
      KeySchema: [
        {AttributeName: "type", KeyType: "HASH"},
        {AttributeName: "time_device_id", KeyType: "RANGE"}
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