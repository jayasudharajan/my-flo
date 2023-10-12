import DynamoTable from './DynamoTable';

class VersionTable extends DynamoTable {

  constructor(tableName, keyName, rangeName, dynamoDbClient) {
    if(!keyName) keyName = 'model';
    if(!rangeName) rangeName = 'version';
    super(tableName, keyName, rangeName, dynamoDbClient);
  }

  getLastVersion(keys) {
    let KeyConditionExpression = "model = :model";
    let ExpressionAttributeValues = {":model": keys.model};
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: KeyConditionExpression,
      ExpressionAttributeValues: ExpressionAttributeValues,
      ScanIndexForward: false,
      limit: 1,
      ProjectionExpression: "version"
    };
    return this.dynamoDbClient.query(params).promise();
  }

  queryPartition(keys) {
    let KeyConditionExpression = "model = :model";
    let ExpressionAttributeValues = {":model": keys.model};
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: KeyConditionExpression,
      ExpressionAttributeValues: ExpressionAttributeValues
    };
    return this.dynamoDbClient.query(params).promise();
  }
}

export default VersionTable;
