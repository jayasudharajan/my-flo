import client from '../../util/dynamoUtil';
import _ from 'lodash';
import uuid from 'node-uuid';
import moment from 'moment';
import DynamoTable from './DynamoTable';

class EmailDeliveryLogTable extends DynamoTable {

  constructor() {
    super('EmailDeliveryLog', 'id');
  }

  /**
   * Create an item.
   */
  create(data) {

    if(!data.id) {
      data.id = uuid.v4();
    }
    data.created_at = moment().toISOString();

    let params = {
      TableName: this.tableName,
      Item: data
    };

    return client.put(params).promise()
      .then(result => {
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

  retrieveByReceiptId(keys) {
    let params = {
      IndexName: 'ReceiptIdIndex',
      TableName: this.tableName,
      KeyConditionExpression: 'receipt_id = :receipt_id',
      ExpressionAttributeValues: {
        ':receipt_id': keys.receipt_id
      }
    };
    return client.query(params).promise();
  }

}

export default EmailDeliveryLogTable;