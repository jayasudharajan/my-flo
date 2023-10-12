import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';
import LogDynamoTable from '../../models/LogDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import TDirectiveResponseLog from './models/TDirectiveResponseLog'

class DirectiveResponseTable extends ValidationMixin(TDirectiveResponseLog, LogDynamoTable)  {

  constructor(dynamoDbClient) {
    super('DirectiveResponseLog', 'icd_id', 'created_at', dynamoDbClient);
  }

  retrieveByIcdId(keys) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      }
    };
    return this.dynamoDbClient.query(params).promise().then(({ Items }) => Items);
  }
}

export default new DIFactory(DirectiveResponseTable, [AWS.DynamoDB.DocumentClient]);