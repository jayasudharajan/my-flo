// TwilioVoiceRequestLog Table for DynamoDB

module.exports = {
  TableName : 'TwilioVoiceRequestLog',
  KeySchema: [
    { AttributeName: 'incident_id', KeyType: 'HASH' },
    { AttributeName: 'created_at', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'incident_id', AttributeType: 'S' },
    { AttributeName: 'created_at', AttributeType: 'S' },
  ],
  ProvisionedThroughput: {
    ReadCapacityUnits: 1,
    WriteCapacityUnits: 1
  }
};
