// AccountGroupAlarmNotificationDeliveryRule Table for DynamoDB

module.exports = {
  TableName : 'AccountGroupAlarmNotificationDeliveryRule',
  KeySchema: [
    { AttributeName: 'group_id', KeyType: 'HASH' },
    { AttributeName: 'alarm_id_system_mode_user_role', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'group_id', AttributeType: 'S' },
    { AttributeName: 'alarm_id_system_mode_user_role', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
