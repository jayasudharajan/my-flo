// ICDAlarmNotificationStatusRegistry Table for DynamoDB

module.exports = {
  TableName : 'ICDAlarmNotificationStatusRegistry',
  KeySchema: [
    { AttributeName: 'id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'id', AttributeType: 'S' },
    { AttributeName: 'icd_id', AttributeType: 'S' },
    { AttributeName: 'icd_alarm_incident_registry_id', AttributeType: 'S' },
    { AttributeName: 'incident_time', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'icd_id',
      KeySchema: [
        { AttributeName: 'icd_id', KeyType: 'HASH' },
        { AttributeName: 'incident_time', KeyType: 'RANGE' }
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
      IndexName: 'icd_alarm_incident_registry_id',
      KeySchema: [
        { AttributeName: 'icd_alarm_incident_registry_id', KeyType: 'HASH' },
        { AttributeName: 'incident_time', KeyType: 'RANGE' }
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
