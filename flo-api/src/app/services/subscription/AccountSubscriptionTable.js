import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TimestampMixin from '../../models/TimestampMixin';
import TAccountSubscription from './models/TAccountSubscription';


class AccountSubscriptionTable extends TimestampMixin(ValidationMixin(TAccountSubscription, DynamoTable)) {

  constructor(dynamoDbClient) {
    super('AccountSubscription', 'account_id', undefined, dynamoDbClient);
  }

  retrieveByStripeCustomerId(stripeCustomerId) {
    return this.dynamoDbClient.query({
      TableName: this.tableName,
      IndexName: 'StripeCustomerIdIndex',
      KeyConditionExpression: 'stripe_customer_id = :stripe_customer_id',
      ExpressionAttributeValues: {
        ':stripe_customer_id': stripeCustomerId
      }
    })
    .promise();
  }

  _addCondition(params, attribute, formatCondition) {
    let expandedParams = params;
    const attrName = `#${ attribute }`;
    const attrValue = `:${ attribute }`;
    const attrData = (params.Item || {})[attribute] || (params.ExpressionAttributeValues || {})[attrValue];
    const cond = formatCondition(attrName, attrValue);

    if (attrData) {
      const conditionExpr = `(attribute_not_exists(${ attrName }) OR (${ cond }))`;

      expandedParams = {
        ...params,
        ConditionExpression: params.ConditionExpression ? 
          `${ params.ConditionExpression } AND ${ conditionExpr }` :
          conditionExpr,
        ExpressionAttributeNames: {
          ...(params.ExpressionAttributeNames || {}),
          [attrName]: attribute
        },
        ExpressionAttributeValues: {
          ...(params.ExpressionAttributeValues || {}),
          [attrValue]: attrData
        }
      };
    }  

    return expandedParams;

  }

  _createParams(params) {
    return this._addCondition(params, 'stripe_subscription_id', (attrName, attrValue) => `${ attrName } = ${ attrValue }`);
  }


  _createPatchParams(params) {
    return super._createPatchParams(this._createParams(params));
  }

  _createUpdateParams(params) {
    return super._createUpdateParams(this._createParams(params));
  }
}

export default new DIFactory(AccountSubscriptionTable, [AWS.DynamoDB.DocumentClient])