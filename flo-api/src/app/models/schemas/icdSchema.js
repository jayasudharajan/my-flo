// ICD Table - DynamoDB

module.exports = {
  TableName : 'ICD',
  KeySchema: [
      { AttributeName: 'id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
      { AttributeName: 'id', AttributeType: 'S' },
      { AttributeName: 'location_id', AttributeType: 'S' },
      { AttributeName: 'device_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    // Get an ICD by device id
    {
      IndexName: "DeviceIdIndex",
      KeySchema: [
        { AttributeName: "device_id", KeyType: "HASH" }
      ],
      Projection: {
        ProjectionType: "ALL"
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    },
    // Get an ICD by location id
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
  },
  StreamSpecification: {
    StreamEnabled: true,
    StreamViewType: 'NEW_AND_OLD_IMAGES'
  }
};
