import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TimestampMixin from '../../models/TimestampMixin';
import TClientUser from './models/TClientUser';

class ClientUserTable extends TimestampMixin(ValidationMixin(TClientUser, DynamoTable)) {

  constructor(dynamoDbClient) {
    super('ClientUser', 'user_id', 'client_id', dynamoDbClient);
  }

  retrieveByUserId(userId) {
    return this.dynamoDbClient.query({
      TableName: this.tableName,
      KeyConditionExpression: '#user_id = :user_id',
      ExpressionAttributeNames: {
        '#user_id': 'user_id'
      },
      ExpressionAttributeValues: {
        ':user_id': userId
      }
    })
    .promise();
  }
}

export default new DIFactory(ClientUserTable, [AWS.DynamoDB.DocumentClient]);