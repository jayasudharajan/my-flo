import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class AccountTable extends DynamoTable {

  constructor() {
    super('Account', 'id');
  }

  retrieveAccountsForGroup(keys) {
    let indexAccountUser = 'AccountGroup';
    let params = {
      TableName: this.tableName,
      IndexName: indexAccountUser,
      KeyConditionExpression: "group_id = :group_id",
      ExpressionAttributeValues: {
        ":group_id": keys.group_id
      }
    };
    return client.query(params).promise();
  }

  retrieveAccountsForOwner(keys) {
    let indexAccountUser = 'OwnerUser';
    let params = {
      TableName: this.tableName,
      IndexName: indexAccountUser,
      KeyConditionExpression: "owner_user_id = :owner_user_id",
      ExpressionAttributeValues: {
        ":owner_user_id": keys.owner_user_id
      }
    };
    return client.query(params).promise();
  }

}

export default AccountTable;