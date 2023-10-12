import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class UserRoleLogTable extends DynamoTable {

  constructor() {
    super('UserRoleLog', 'user_id', 'created_at');
  }

  retrieveByUserId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': keys.user_id
      }
    };
    return client.query(params).promise();
  }

  retrieveLatestByUserId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': keys.user_id
      },
      ScanIndexForward: false,
      Limit: 1
    };
    return client.query(params).promise();
  }

}

export default UserRoleLogTable;