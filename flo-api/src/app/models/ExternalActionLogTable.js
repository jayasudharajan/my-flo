import client from '../../util/dynamoUtil';
import _ from 'lodash';
import LogDynamoTable from './LogDynamoTable';

class ExternalActionLogTable extends LogDynamoTable {

  constructor() {
    super('ExternalActionLog', 'icd_id', 'created_at');
  }

  retrieveByIcdId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      }
    };
    return client.query(params).promise();
  }

}

export default ExternalActionLogTable;