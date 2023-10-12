import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TimestampMixin from '../../models/TimestampMixin';
import TAlertFeedback from './models/TAlertFeedback';

class AlertFeedbackTable extends TimestampMixin(ValidationMixin(TAlertFeedback, DynamoTable))  {

  constructor(dynamoDbClient) {
    super('AlertFeedback', 'icd_id', 'incident_id', dynamoDbClient);
  }
}

export default new DIFactory(AlertFeedbackTable, [AWS.DynamoDB.DocumentClient]);