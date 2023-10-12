import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class ResetTokenTable extends DynamoTable {

  constructor() {
    super('ResetToken', 'user_id');
  }

  create(data) {
    // TODO: payload is currently created in controller, 
    // should go here / have validation.
    // user_id, reset_password_token, reset_password_expires
    let params = {
      TableName: this.tableName,
      Item: data
    };
    return client.put(params).promise();
  }

  retrieveByToken(token) {
    let params = {
      TableName: this.tableName,
      IndexName: 'ResetTokenIndex',
      KeyConditionExpression: "reset_password_token = :reset_password_token",
      ExpressionAttributeValues: {
        ":reset_password_token": token
      }
    };
    return client.query(params).promise();
  }

}

export default ResetTokenTable;