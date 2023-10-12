import DIFactory from '../../../util/DIFactory';
import AWS from 'aws-sdk';
import LogDynamoTable from '../../models/LogDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import TInsuranceLetterRequestLog from './models/TInsuranceLetterRequestLog'

class InsuranceLetterRequestLogTable extends ValidationMixin(TInsuranceLetterRequestLog, LogDynamoTable) {

  constructor(dynamoDbClient) {
    super('InsuranceLetterRequestLog', 'location_id', 'created_at', dynamoDbClient);
  }
}

export default new DIFactory(InsuranceLetterRequestLogTable, [AWS.DynamoDB.DocumentClient]);