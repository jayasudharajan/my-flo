import DIFactory from  '../../../util/DIFactory';
import { ValidationMixin } from '../../models/ValidationMixin';
import AWS from 'aws-sdk';
import VersionTable from '../../models/VersionTable';
import TUltimaVersion from './models/TUltimaVersion'

class UltimaVersionTable extends ValidationMixin(TUltimaVersion, VersionTable) {

  constructor(dynamoDbClient) {
    super('UltimaVersion', undefined, undefined, dynamoDbClient)
  }

  retrieveByModel(keys) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'model = :model',
      ExpressionAttributeValues: {
        ':model': keys.model
      }
    };
    return this.dynamoDbClient.query(params).promise().then(({ Items })=> Items);
  }
}

export default new DIFactory(UltimaVersionTable, [AWS.DynamoDB.DocumentClient]);

