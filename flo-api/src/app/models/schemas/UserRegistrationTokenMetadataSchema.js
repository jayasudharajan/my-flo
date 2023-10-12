// UserRegistrationTokenMetadata Table for DynamoDB

module.exports = {
  TableName : 'UserRegistrationTokenMetadata',
  KeySchema: [
    { AttributeName: 'token_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'token_id', AttributeType: 'S' },
    { AttributeName: 'email_hash', AttributeType: 'S' },
    { AttributeName: 'created_at', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'EmailHashIndex',
      KeySchema: [
        { AttributeName: 'email_hash', KeyType: 'HASH' },
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
