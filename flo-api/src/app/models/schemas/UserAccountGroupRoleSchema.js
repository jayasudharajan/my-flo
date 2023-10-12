// UserAccountGroupRole Table for DynamoDB

module.exports = {
  TableName : 'UserAccountGroupRole',
  KeySchema: [
    { AttributeName: 'user_id', KeyType: 'HASH' },
    { AttributeName: 'group_id', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'user_id', AttributeType: 'S' },
    { AttributeName: 'group_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  },
  GlobalSecondaryIndexes: [
    {
      IndexName: "GroupIdIndex",
      KeySchema: [
        { AttributeName: "group_id", KeyType: "HASH" },
        { AttributeName: "user_id", KeyType: "RANGE" }
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
