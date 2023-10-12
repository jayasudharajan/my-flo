// ICDAlarmIncidentRegistry Table for DynamoDB

module.exports = {
  TableName : 'ICDAlarmIncidentRegistry',
  KeySchema: [
    { AttributeName: 'id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'id', AttributeType: 'S' },
    { AttributeName: 'icd_id', AttributeType: 'S' },
    { AttributeName: 'acknowledged_by_user', AttributeType: 'N' },
    { AttributeName: 'incident_time', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: "ICDIdIndex",
      KeySchema: [
        { AttributeName: "icd_id", KeyType: "HASH" },
        { AttributeName: "acknowledged_by_user", KeyType: "RANGE" }        
      ],
      Projection: {
        ProjectionType: "ALL"
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    },
    {
      IndexName: "ICDIdIncidentTimeIndex",
      KeySchema: [
        { AttributeName: "icd_id", KeyType: "HASH" },
        { AttributeName: "incident_time", KeyType: "RANGE" }
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
