// UserLocationRole Table for DynamoDB

module.exports = {
  TableName : 'UserLocationRole',
  KeySchema: [
    { AttributeName: 'user_id', KeyType: 'HASH' },
    { AttributeName: 'location_id', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'user_id', AttributeType: 'S' },
    { AttributeName: 'location_id', AttributeType: 'S' },
    { AttributeName: 'account_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'LocationIdIndex',
      KeySchema: [
        { AttributeName: 'location_id', KeyType: 'HASH' }
      ],
      Projection: {
        ProjectionType: 'ALL'
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    },
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
