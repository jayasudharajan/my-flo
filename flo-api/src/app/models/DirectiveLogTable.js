import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';
import AWS from 'aws-sdk';
import DIFactory from  '../../util/DIFactory';

class DirectiveLogTable extends DynamoTable {

  constructor(dynamoDbClient) {
    super('DirectiveLog', 'icd_id', 'created_at', dynamoDbClient);
  }

  retrieveByICDId(keys) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      },
      ScanIndexForward: false
    };
    return this.dynamoDbClient.query(params).promise();
  }

  retrieveByDirectiveId(directiveId) {
    const params = {
      TableName: this.tableName,
      IndexName: 'DirectiveIdIndex',
      KeyConditionExpression: 'directive_id = :directive_id',
      ExpressionAttributeValues: {
        ':directive_id': directiveId
      }
    };
    return this.dynamoDbClient.query(params).promise();
  }
}

export default new DIFactory(DirectiveLogTable, [AWS.DynamoDB.DocumentClient]);