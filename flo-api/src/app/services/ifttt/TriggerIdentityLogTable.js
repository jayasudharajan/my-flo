import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TTriggerIdentityLog from './models/TTriggerIdentityLog';

class TriggerIdentityLogTable extends ValidationMixin(TTriggerIdentityLog, DynamoTable)  {

  constructor(dynamoDbClient) {
    super('IFTTTTriggerIdentityLog', 'trigger_identity', 'user_id', dynamoDbClient);
  }

  marshal({ trigger_identity, flo_trigger_id, ...data }) {
    return super.marshal({
      ...data,
      trigger_identity,
      flo_trigger_id,
      flo_trigger_id_trigger_identity: `${ flo_trigger_id }_${ trigger_identity }`
    });
  }

  marshalPatch(keys, data) {
    const { trigger_identity } = keys;
    const { flo_trigger_id } = data;

    return super.marshalPatch(keys, ({
      ...data,
      flo_trigger_id_trigger_identity: `${ flo_trigger_id }_${ trigger_identity }`
    }));
  }

  logTriggerIdentityIfDoesNotExists(data) {
    return this.marshal(data)
      .then(marshalledData => {
        return this.dynamoDbClient.put({
          TableName: this.tableName,
          ConditionExpression: 'attribute_not_exists(#hash_key)',
          ExpressionAttributeNames: {
            '#hash_key': 'trigger_identity',
          },
          Item: marshalledData
        })
        .promise()
    })
    .catch(err => {
      if (err.name === 'ConditionalCheckFailedException') {
        return Promise.resolve('Trigger identity is already in the logs');
      } else {
        return Promise.reject(err);
      }
    });
  }

  retrieveByUserIdFloTriggerId(userId, floTriggerId) {
    return this.dynamoDbClient.query({
      TableName: this.tableName,
      IndexName: 'UserIdFloTriggerIdTriggerIdentityIndex',
      KeyConditionExpression: 'user_id = :user_id AND begins_with(#range_key, :flo_trigger_id)',
      ExpressionAttributeNames: {
        '#range_key': 'flo_trigger_id_trigger_identity'
      },
      ExpressionAttributeValues: {
        ':user_id': userId,
        ':flo_trigger_id': `${ floTriggerId }`
      }
    })
    .promise();
  }
}

export default new DIFactory(TriggerIdentityLogTable, [AWS.DynamoDB.DocumentClient]);