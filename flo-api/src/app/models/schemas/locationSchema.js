// location Table - DynamoDB

module.exports = {
  TableName : 'Location',
  KeySchema: [
      { AttributeName: 'account_id', KeyType: 'HASH' },
      { AttributeName: 'location_id', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
      { AttributeName: 'account_id', AttributeType: 'S' },
      { AttributeName: 'location_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: "LocationIdIndex",
      KeySchema: [
        { AttributeName: "location_id", KeyType: "HASH" }
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
