import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class PendingScheduledTaskTable extends DynamoTable {

  constructor() {
    super('PendingScheduledTask', 'task_id');
  }

  retrieveByIcdId(keys) {
    let params = {
      TableName: this.tableName,
      IndexName: 'IcdId',
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      }
    };
    return client.query(params).promise();
  }

  retrieveByIcdIdTaskId(keys) {
    let params = {
      TableName: this.tableName,
      IndexName: 'IcdId',
      KeyConditionExpression: 'icd_id = :icd_id AND task_id = :task_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id,
        ':task_id': keys.task_id
      }
    };
    return client.query(params).promise();
  }
}

export default PendingScheduledTaskTable;