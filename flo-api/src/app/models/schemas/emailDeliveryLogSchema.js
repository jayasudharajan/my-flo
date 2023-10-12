// EmailDeliveryLog Table for DynamoDB

module.exports = {
  TableName : 'EmailDeliveryLog',
  KeySchema: [
    { AttributeName: 'id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'id', AttributeType: 'S' },
    { AttributeName: 'receipt_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: "ReceiptIdIndex",
      KeySchema: [
        { AttributeName: "receipt_id", KeyType: "HASH" }
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
