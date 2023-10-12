// FloDetectEventChronology Table for DynamoDB

module.exports = {
  TableName : 'FloDetectEventChronology',
  KeySchema: [
    { AttributeName: 'device_id_request_id', KeyType: 'HASH' },
    { AttributeName: 'start', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'device_id_request_id', AttributeType: 'S' },
    { AttributeName: 'start', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
