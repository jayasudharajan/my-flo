import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class AccountGroupTable extends DynamoTable {

  constructor() {
    super('AccountGroup', 'id');
  }

  retrieveByName(keys) {
    let params = {
      TableName: this.tableName,
      IndexName: "NameIndex",
      KeyConditionExpression: "#name = :name",
      ExpressionAttributeNames: { "#name": "name" },
      ExpressionAttributeValues: {
        ":name": keys.name
      }
    };
    return client.query(params).promise();
  }

}

export default AccountGroupTable;