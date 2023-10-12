import AWS from 'aws-sdk';
import TAccessControl from './models/TAccessControl';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';

class AccessControlTable extends ValidationMixin(TAccessControl, DynamoTable) {
  constructor(dynamoDbClient) {
    super(
      'AccessControl',
      'method_id',  
      undefined, 
      dynamoDbClient 
    );
  }
}

export default new DIFactory(AccessControlTable, [AWS.DynamoDB.DocumentClient]);