// AlarmNotificationDeliveryFilter Table for DynamoDB

module.exports = {
  TableName : 'AlarmNotificationDeliveryFilter',
  KeySchema: [
    { AttributeName: 'icd_id', KeyType: 'HASH' },
    { AttributeName: 'alarm_id_system_mode', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'icd_id', AttributeType: 'S' },
    { AttributeName: 'alarm_id_system_mode', AttributeType: 'S' },
    { AttributeName: 'status', AttributeType: 'N' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: "ICDIdStatusIndex",
      KeySchema: [
        { AttributeName: "icd_id", KeyType: "HASH" },
        { AttributeName: "status", KeyType: "RANGE" }
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
