// InsuranceLetterRequestLog Table for DynamoDB

module.exports = {
  TableName: 'InsuranceLetterRequestLog',
  KeySchema: [
    {AttributeName: 'location_id', KeyType: 'HASH'},
    {AttributeName: 'created_at', KeyType: 'RANGE'}
  ],
  AttributeDefinitions: [
    {AttributeName: 'location_id', AttributeType: 'S'},
    {AttributeName: 'created_at', AttributeType: 'S'}
  ],
  ProvisionedThroughput: {
    ReadCapacityUnits: 1,
    WriteCapacityUnits: 1
  }
};