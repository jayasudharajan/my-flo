// SubscriptionPlan Table for DynamoDB

module.exports = {
  TableName : 'SubscriptionPlan',
  KeySchema: [
    { AttributeName: 'plan_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'plan_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
