import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class UserAccountRoleTable extends DynamoTable {

  constructor() {
    super('UserAccountRole', 'user_id', 'account_id');
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

  /**
   * Retrieve UserAccountRoles based on account_id.
   */
  retrieveByAccountId(keys) {
    let indexName = "AccountIdIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: "account_id = :account_id",
      ExpressionAttributeValues: {
        ":account_id": keys.account_id
      }
    };

    return client.query(params).promise();
  }

}


export default UserAccountRoleTable;