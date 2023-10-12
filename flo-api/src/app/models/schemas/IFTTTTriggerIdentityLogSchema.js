// IFTTTTriggerIdentityLog Table for DynamoDB

module.exports = {
  TableName: 'IFTTTTriggerIdentityLog',
  KeySchema: [
    {AttributeName: 'trigger_identity', KeyType: 'HASH'},
    {AttributeName: 'user_id', KeyType: 'RANGE'}
  ],
  AttributeDefinitions: [
    {AttributeName: 'trigger_identity', AttributeType: 'S'},
    {AttributeName: 'flo_trigger_id_trigger_identity', AttributeType: 'S'},
    {AttributeName: 'user_id', AttributeType: 'S'}
  ],
  ProvisionedThroughput: {
    ReadCapacityUnits: 1,
    WriteCapacityUnits: 1
  },
  GlobalSecondaryIndexes: [
    {
      IndexName: "UserIdFloTriggerIdTriggerIdentityIndex",
      KeySchema: [
        {AttributeName: "user_id", KeyType: "HASH"},
        {AttributeName: "flo_trigger_id_trigger_identity", KeyType: "RANGE"}
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