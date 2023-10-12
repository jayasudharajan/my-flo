import _ from 'lodash';
import DynamoTable from '../../models/DynamoTable';
import DIFactory from  '../../../util/DIFactory';
import { ValidationMixin } from '../../models/ValidationMixin';
import TZITResult from './models/TZITResult'
import AWS from 'aws-sdk';

class ZITResultTable extends ValidationMixin(TZITResult, DynamoTable) {

  constructor(dynamoDbClient) {
    super('ZITResult', 'icd_id', 'round_id', dynamoDbClient);
  }

  orderItems(items) {
    return _.orderBy(items, ['started_at'], ['desc'])
  }

  retrieveByIcdId(keys) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      }
    };
    return this.dynamoDbClient.query(params).promise().then(({ Items }) => this.orderItems(Items));
  }
}

export default new DIFactory(ZITResultTable, [AWS.DynamoDB.DocumentClient]);