// ZITResult Table for DynamoDB

module.exports = {
  TableName : 'ZITResult',
  KeySchema: [
    { AttributeName: 'icd_id', KeyType: 'HASH' },
    { AttributeName: 'round_id', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'icd_id', AttributeType: 'S' },
    { AttributeName: 'round_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
