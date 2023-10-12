// PressureTestProfile Table - DynamoDB

module.exports = {
  TableName : 'SystemUserRoles',
  KeySchema: [
      { AttributeName: 'id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
      { AttributeName: 'id', AttributeType: 'S' },
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1, 
      WriteCapacityUnits: 1
  }
};