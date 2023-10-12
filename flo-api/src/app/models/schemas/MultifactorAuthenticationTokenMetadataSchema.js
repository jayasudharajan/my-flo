// MultifactorAuthenticationTokenMetadata Table for DynamoDB

module.exports = {
  TableName : 'MultifactorAuthenticationTokenMetadata',
  KeySchema: [
    { AttributeName: 'token_id', KeyType: 'HASH' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'token_id', AttributeType: 'S' }
  ],
  ProvisionedThroughput: {
      ReadCapacityUnits: 1,
      WriteCapacityUnits: 1
  }
};
