import LogDynamoTable from '../../models/LogDynamoTable';
import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';

class TwilioVoiceRequestLogTable extends LogDynamoTable {

  constructor(dynamoDbClient) {
    super('TwilioVoiceRequestLog', 'incident_id', 'created_at', dynamoDbClient);
  }
}

export default new DIFactory(TwilioVoiceRequestLogTable, [AWS.DynamoDB.DocumentClient]);