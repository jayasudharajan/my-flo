// UserAccountRole Table for DynamoDB

module.exports = {
  TableName : 'UserAccountRole',
  KeySchema: [
    { AttributeName: 'user_id', KeyType: 'HASH' },
    { AttributeName: 'account_id', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'user_id', AttributeType: 'S' },
    { AttributeName: 'account_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'AccountIdIndex',
      KeySchema: [
        { AttributeName: 'account_id', KeyType: 'HASH' }
      ],
      Projection: {
        ProjectionType: 'ALL'
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
