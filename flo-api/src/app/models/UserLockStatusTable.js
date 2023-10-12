import client from '../../util/dynamoUtil';
import _ from 'lodash';
import LogDynamoTable from './LogDynamoTable';

class UserLockStatusTable extends LogDynamoTable {

  constructor() {
    super('UserLockStatus', 'user_id', 'created_at');
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

}

export default UserLockStatusTable;