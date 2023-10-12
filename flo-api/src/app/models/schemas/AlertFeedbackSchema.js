// AlertFeedback Table for DynamoDB

module.exports = {
  TableName : 'AlertFeedback',
  KeySchema: [
    { AttributeName: 'icd_id', KeyType: 'HASH' },
    { AttributeName: 'incident_id', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'icd_id', AttributeType: 'S' },
    { AttributeName: 'incident_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
