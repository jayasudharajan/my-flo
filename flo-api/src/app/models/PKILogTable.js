import client from '../../util/dynamoUtil';
import _ from 'lodash';
import LogDynamoTable from './LogDynamoTable';

class PKILogTable extends LogDynamoTable {

  constructor() {
    super('PKILog', 'task_id', 'created_at');
  }

  retrieveByTaskId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'task_id = :task_id',
      ExpressionAttributeValues: {
        ':task_id': keys.task_id
      }
    };
    return client.query(params).promise();
  }

}

export default PKILogTable;