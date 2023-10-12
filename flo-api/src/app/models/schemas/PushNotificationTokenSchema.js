// PushNotificationToken Table for DynamoDB

module.exports = {
  TableName : 'PushNotificationToken',
  KeySchema: [
    { AttributeName: 'mobile_device_id', KeyType: 'HASH' },
    { AttributeName: 'client_id', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'mobile_device_id', AttributeType: 'S' },
    { AttributeName: 'client_id', AttributeType: 'S' },
    { AttributeName: 'user_id', AttributeType: 'S' },
    { AttributeName: 'mobile_device_id_client_id', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'UserIdMobileIdClientIdIndex',
      KeySchema: [
        { AttributeName: 'user_id', KeyType: 'HASH' },
        { AttributeName: 'mobile_device_id_client_id', KeyType: 'RANGE' }
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
