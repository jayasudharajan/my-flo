import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';
import uuid from 'node-uuid';
import moment from 'moment';

class RegistrationTokenTable extends DynamoTable {

  constructor() {
    super('RegistrationToken', 'token1', 'token2');
  }

  create(data) {

    // Create two random tokens (guids).  
    data["token1"] = uuid.v4();
    data["token2"] = uuid.v4();

    // Timestamp.
    data["created_at"] = moment().valueOf();

    // Active the reg token.
    data["is_active"] = true;

    // Also expecting user_id.
    if(!data.user_id) {
      return new Promise((resolve, reject) => {
        reject({ message: "Need user_id."})
      });
    }

    let params = {
      TableName: this.tableName,
      Item: data
    };

    return client.put(params).promise()
      .then(result => {
        // NOTE: if empty, means was successful.
        // Return back the item with id.
        if(_.isEmpty(result)) {
          return new Promise((resolve, reject) => {
            resolve(data);
          });
        } else {
          return new Promise((resolve, reject) => {
            reject({ message: "Unable to create item."})
          });
        }
      });

  }

  /*
  queryPartition(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'token1 = :token1',
      ExpressionAttributeValues: {
        ':token1': keys.token1
      }
    };
    return client.query(params).promise();
  }
  */
 
}

export default RegistrationTokenTable;