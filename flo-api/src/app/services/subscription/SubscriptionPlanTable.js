import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TimestampMixin from '../../models/TimestampMixin';
import TSubscriptionPlan from './models/TSubscriptionPlan';

class SubscriptionPlanTable extends TimestampMixin(ValidationMixin(TSubscriptionPlan, DynamoTable)) {

  constructor(dynamoDbClient) {
    super('SubscriptionPlan', 'plan_id', undefined, dynamoDbClient);
  }
}

export default new DIFactory(SubscriptionPlanTable, [AWS.DynamoDB.DocumentClient])