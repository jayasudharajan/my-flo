// AclRole Table for DynamoDB

module.exports = {
  TableName : 'AclRole',
  KeySchema: [
    { AttributeName: 'role_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'role_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
