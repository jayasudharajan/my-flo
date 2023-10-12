// PendingScheduledTask Table for DynamoDB

module.exports = {
  TableName : 'PendingScheduledTask',
  KeySchema: [
    { AttributeName: 'task_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'task_id', AttributeType: 'S' },
    { AttributeName: 'icd_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'IcdId',
      KeySchema: [
        { AttributeName: 'icd_id', KeyType: 'HASH' },
        { AttributeName: 'task_id', KeyType: 'RANGE' }
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