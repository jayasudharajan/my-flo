// Account Table - DynamoDB

module.exports = {
  TableName : 'Account',
  KeySchema: [
      { AttributeName: 'id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
      { AttributeName: 'id', AttributeType: 'S' },
      { AttributeName: 'group_id', AttributeType: 'S' },
      { AttributeName: 'owner_user_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: "AccountGroup",
      KeySchema: [
        { AttributeName: "group_id", KeyType: "HASH" }
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
      IndexName: "OwnerUser",
      KeySchema: [
        { AttributeName: "owner_user_id", KeyType: "HASH" },
        { AttributeName: 'id', KeyType: 'RANGE' }
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
  },
  StreamSpecification: {
    StreamEnabled: true,
    StreamViewType: 'NEW_AND_OLD_IMAGES'
  }
};
