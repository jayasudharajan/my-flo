import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import ValidationMixin from '../../models/ValidationMixin';
import TimestampMixin from '../../models/TimestampMixin';
import TPushNotificationToken from './models/TPushNotificationToken';
import DynamoTable from '../../models/DynamoTable';

class PushNotificationTokenTable extends TimestampMixin(ValidationMixin(TPushNotificationToken, DynamoTable)) {
  constructor(dynamoDbClient) {
    super('PushNotificationToken', 'mobile_device_id', 'client_id', dynamoDbClient);
  }

  composeKeys({ client_id, mobile_device_id }) {
    return {
      mobile_device_id_client_id: `${ mobile_device_id }:${ client_id }`
    };
  }

  marshal(data) {
    const { aws_endpoint_id } = data;
    const sanitizedAWSEndpointId = aws_endpoint_id ?
      {
        aws_endpoint_id: aws_endpoint_id.toLowerCase()
      } :
      {};

    return super.marshal({
      ...data,
      ...this.composeKeys(data),
      ...sanitizedAWSEndpointId
    });
  }

  stripCompoundKeys(data) {
    return _.omit(data, ['mobile_device_id_client_id']);
  }

  retrieve(keys) {
    return super.retrieve(keys)
      .then(result => ({
        ...result,
        Item: this.stripCompoundKeys(result.Item)
      }));
  }

  retrieveByUserId(userId) {
    return this.dynamoDbClient.query({
      TableName: this.tableName,
      IndexName: 'UserIdMobileIdClientIdIndex',
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': userId
      }
    })
    .promise()
    .then(result => ({
      ...result,
      Items: result.Items.map(item => this.stripCompoundKeys(item))
    }));
  }
}

export default new DIFactory(PushNotificationTokenTable, [AWS.DynamoDB.DocumentClient]);