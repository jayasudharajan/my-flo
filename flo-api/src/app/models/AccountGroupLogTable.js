import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class AccountGroupLogTable extends DynamoTable {

  constructor() {
    super('AccountGroupLog', 'subresource', 'created_at');
  }

  retrieveByResource(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'subresource = :subresource',
      ExpressionAttributeValues: {
        ':subresource': keys.subresource
      }
    };
    return client.query(params).promise();
  }

  retrieveLatestByResource(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'subresource = :subresource',
      ExpressionAttributeValues: {
        ':subresource': keys.subresource
      },
      ScanIndexForward: false,
      Limit: 1
    };
    return client.query(params).promise();
  }

}

export default AccountGroupLogTable;