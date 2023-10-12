import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TAlertFeedbackFlow from './models/TAlertFeedbackFlow';

class AlertFeedbackFlowTable extends ValidationMixin(TAlertFeedbackFlow, DynamoTable)  {

  constructor(dynamoDbClient) {
    super('AlertFeedbackFlow', 'alarm_id', 'system_mode', dynamoDbClient);
  }
}

export default new DIFactory(AlertFeedbackFlowTable, [AWS.DynamoDB.DocumentClient]);