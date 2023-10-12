import _ from 'lodash';
import DynamoTable from './DynamoTable';

import DIFactory from '../../util/DIFactory';
import AWS from 'aws-sdk';

class UserLocationRoleTable extends DynamoTable {

  constructor(dynamoDbClient) {
    super('UserLocationRole', 'user_id', 'location_id', dynamoDbClient);
  }

  retrieveByUserId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': keys.user_id
      }
    };
    return this.dynamoDbClient.query(params).promise();
  }

  /**
   * Retrieve UserAccountRoles based on account_id.
   */
  retrieveByLocationId(keys) {
    let indexName = "LocationIdIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: "location_id = :location_id",
      ExpressionAttributeValues: {
        ":location_id": keys.location_id
      }
    };

    return this.dynamoDbClient.query(params).promise();
  }
}

export default new DIFactory(UserLocationRoleTable, [AWS.DynamoDB.DocumentClient]);