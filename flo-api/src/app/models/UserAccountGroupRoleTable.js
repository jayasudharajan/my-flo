import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class UserAccountGroupRoleTable extends DynamoTable {

  constructor() {
    super('UserAccountGroupRole', 'user_id', 'group_id');
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

export default UserAccountGroupRoleTable;