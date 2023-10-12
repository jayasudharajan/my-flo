// ICDAlarmNotificationDeliveryRule Table for DynamoDB

module.exports = {
  TableName : 'ICDAlarmNotificationDeliveryRule',
  KeySchema: [
    { AttributeName: 'alarm_id', KeyType: 'HASH' },
    { AttributeName: 'system_mode', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'alarm_id', AttributeType: 'N' },
    { AttributeName: 'system_mode', AttributeType: 'N' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'SystemModeIndex',
      KeySchema: [
        { AttributeName: 'system_mode', KeyType: 'HASH' },
        { AttributeName: 'alarm_id', KeyType: 'RANGE' }        
      ],
      Projection: {
        ProjectionType: 'ALL'
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
