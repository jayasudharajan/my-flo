import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TimestampMixin from '../../models/TimestampMixin';
import TCustomerEmailSubscription from './models/TCustomerEmailSubscription';


class CustomerEmailSubscriptionTable extends TimestampMixin(ValidationMixin(TCustomerEmailSubscription, DynamoTable)) {

  constructor(dynamoDbClient) {
    super('CustomerEmailSubscription', 'user_id', undefined, dynamoDbClient);
  }

  updateSubscriptions(userId, subscriptions) {
    let i = 0;
    const { values, names, setExprs } = 
    _.map(subscriptions, (isSubscribed, emailId) => {
      const j = i++;

      return {
        name: { [`#email_id_${ j }`]: emailId },
        value: { [`:email_id_${ j }`]: isSubscribed },
        setExpr: `#subscriptions.#email_id_${ j } = :email_id_${ j }`
      };
    })
    .reduce(({ values, names, setExprs }, { name, value, setExpr }) => ({
      values: { ...values, ...value },
      names: { ...names, ...name },
      setExprs: [...setExprs, setExpr]
    }), { values: {} , names: {}, setExprs: [] });

    return this.dynamoDbClient.update({
      TableName: this.tableName,
      ConditionExpression: 'attribute_exists(#user_id)',
      Key: {
        user_id: userId
      },
      UpdateExpression: `SET ${ setExprs.join(', ') }`,
      ExpressionAttributeNames: {
        ...names,
        '#user_id': 'user_id',
        '#subscriptions': 'subscriptions'
      },
      ExpressionAttributeValues: {
        ...values
      }
    })
    .promise()
    .catch(err => {
      if (err.name === 'ConditionalCheckFailedException') {
        return this.create({ user_id: userId, subscriptions });
      } else {
        return Promise.reject(err);
      }
    });
  }
}

export default new DIFactory(CustomerEmailSubscriptionTable, [AWS.DynamoDB.DocumentClient]);