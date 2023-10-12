// RefreshTokenMetadata Table for DynamoDB

module.exports = {
  TableName : 'RefreshTokenMetadata',
  KeySchema: [
    { AttributeName: 'token_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'token_id', AttributeType: 'S' },
    { AttributeName: 'access_token_id', AttributeType: 'S' },
    { AttributeName: 'user_id', AttributeType: 'S' },
    { AttributeName: 'created_at', AttributeType: 'S' },
    { AttributeName: 'user_id_client_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'AccessTokenIdIndex',
      KeySchema: [
        { AttributeName: 'access_token_id', KeyType: 'HASH' }
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
      IndexName: 'UserIdCreatedAtIndex',
      KeySchema: [
        { AttributeName: 'user_id', KeyType: 'HASH' },
        { AttributeName: 'created_at', KeyType: 'RANGE' }
      ],
      Projection: {
        ProjectionType: 'ALL'
      },
      ProvisionedThroughput:  {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    },
    {
      IndexName: 'UserIdClientIdCreatedAtIndex',
      KeySchema: [
        { AttributeName: 'user_id_client_id', KeyType: 'HASH' },
        { AttributeName: 'created_at', KeyType: 'RANGE' }
      ],
      Projection: {
        ProjectionType: 'ALL'
      },
      ProvisionedThroughput:  {
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
