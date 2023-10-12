// ICDLog Table for DynamoDB

module.exports = {
  TableName : 'ICDLog',
  KeySchema: [
    { AttributeName: 'icd_id', KeyType: 'HASH' },
    { AttributeName: 'created_at', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'icd_id', AttributeType: 'S' },
    { AttributeName: 'created_at', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
