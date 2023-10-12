// ResetToken Table - DynamoDB

module.exports = {
  TableName : 'ResetToken',
  KeySchema: [
      { AttributeName: 'user_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
      { AttributeName: 'user_id', AttributeType: 'S' },
      { AttributeName: 'reset_password_token', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: "ResetTokenIndex",
      KeySchema: [
        { AttributeName: "reset_password_token", KeyType: "HASH" }
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
