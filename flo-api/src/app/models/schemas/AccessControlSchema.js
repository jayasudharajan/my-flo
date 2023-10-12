// AccessControl Table for DynamoDB

module.exports = {
  TableName : 'AccessControl',
  KeySchema: [
    { AttributeName: 'method_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'method_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
