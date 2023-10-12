import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TVPNWhitelist from './models/TVPNWhitelist';

class VPNWhitelistTable extends ValidationMixin(TVPNWhitelist, DynamoTable) {

  constructor(dynamoDbClient) {
    super(
      'VPNWhitelist',
      'device_id',
      undefined,
      dynamoDbClient
    );
  }
}

export default new DIFactory(VPNWhitelistTable, [AWS.DynamoDB.DocumentClient]);