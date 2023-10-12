// ICDAlarmIncidentRegistryLog Table for DynamoDB

module.exports = {
  TableName : 'ICDAlarmIncidentRegistryLog',
  KeySchema: [
    { AttributeName: 'icd_alarm_incident_registry_id', KeyType: 'HASH' },
    { AttributeName: 'delivery_medium_status', KeyType: 'RANGE' },
  ],
  AttributeDefinitions: [
    { AttributeName: 'icd_alarm_incident_registry_id', AttributeType: 'S' },
    { AttributeName: 'delivery_medium_status', AttributeType: 'N' },
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