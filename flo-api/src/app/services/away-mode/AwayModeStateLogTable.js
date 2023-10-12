import AWS from 'aws-sdk';
import TAwayModeStateLog from './models/TAwayModeStateLog';
import DIFactory from  '../../../util/DIFactory';
import LogDynamoTable from '../../models/LogDynamoTable';
import ValidationMixin from '../../models/ValidationMixin';

class AwayModeStateLogTable extends ValidationMixin(TAwayModeStateLog, LogDynamoTable) {
  constructor(dynamoDbClient) {
    super('AwayModeStateLog', 'icd_id', 'created_at', dynamoDbClient);
  }
}

export default new DIFactory(AwayModeStateLogTable, [AWS.DynamoDB.DocumentClient]);