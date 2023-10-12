// AccountGroupLog Table for DynamoDB

module.exports = {
  TableName : 'AccountGroupLog',
  KeySchema: [
    { AttributeName: 'subresource', KeyType: 'HASH' },
    { AttributeName: 'created_at', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'subresource', AttributeType: 'S' },
    { AttributeName: 'created_at', AttributeType: 'S' }
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
