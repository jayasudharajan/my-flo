// AccountSubscription Table for DynamoDB

module.exports = {
  TableName : 'AccountSubscription',
  KeySchema: [
    { AttributeName: 'account_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'account_id', AttributeType: 'S' },
    { AttributeName: 'stripe_customer_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'StripeCustomerIdIndex',
      KeySchema: [
        { AttributeName: 'stripe_customer_id', KeyType: 'HASH' }
      ],
      Projection: {
        ProjectionType: "ALL"
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
