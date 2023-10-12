// AlertFeedbackFlow Table for DynamoDB

module.exports = {
  TableName : 'AlertFeedbackFlow',
  KeySchema: [
    { AttributeName: 'alarm_id', KeyType: 'HASH' },
    { AttributeName: 'system_mode', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'alarm_id', AttributeType: 'N' },
    { AttributeName: 'system_mode', AttributeType: 'N' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
