// UserAlarmNotificationDeliveryRule Table for DynamoDB

module.exports = {
  TableName : 'UserAlarmNotificationDeliveryRule',
  KeySchema: [
    { AttributeName: 'user_id', KeyType: 'HASH' },
    { AttributeName: 'location_id_alarm_id_system_mode', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'user_id', AttributeType: 'S' },
    { AttributeName: 'location_id_alarm_id_system_mode', AttributeType: 'S' },
    { AttributeName: 'location_id', AttributeType: 'S' },
    { AttributeName: 'alarm_id', AttributeType: 'N' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'LocationIdAlarmIdSystemModeIndex',
      KeySchema: [
        { AttributeName: 'location_id_alarm_id_system_mode', KeyType: 'HASH' }
      ],
      Projection: {
        ProjectionType: 'ALL'
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    },
    {
      IndexName: 'LocationIdAlarmIdIndex',
      KeySchema: [
        { AttributeName: 'location_id', KeyType: 'HASH' },
        { AttributeName: 'alarm_id', KeyType: 'RANGE' }
      ],
      Projection: {
        ProjectionType: 'ALL'
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
      }
    },
    {
      IndexName: 'LocationIdAlarmIdSystemModeUserIdIndex',
      KeySchema: [
        { AttributeName: 'location_id_alarm_id_system_mode', KeyType: 'HASH' },
        { AttributeName: 'user_id', KeyType: 'RANGE' }
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
  }
};
