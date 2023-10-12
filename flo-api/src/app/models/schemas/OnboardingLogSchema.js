// OnboardingLog Table for DynamoDB

module.exports = {
  TableName : 'OnboardingLog',
  KeySchema: [
    { AttributeName: 'icd_id', KeyType: 'HASH' },
    { AttributeName: 'created_at', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'icd_id', AttributeType: 'S' },
    { AttributeName: 'created_at', AttributeType: 'S' },
    { AttributeName: 'event', AttributeType: 'N' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'EventIndex',
      KeySchema: [
        { AttributeName: 'icd_id', KeyType: 'HASH' },
        { AttributeName: 'event', KeyType: 'RANGE' }
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
