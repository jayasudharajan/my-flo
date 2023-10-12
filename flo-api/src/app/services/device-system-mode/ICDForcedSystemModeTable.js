import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TimestampMixin from '../../models/TimestampMixin';
import TICDForcedSystemMode from './models/TICDForcedSystemMode';

class ICDForcedSystemModeTable extends TimestampMixin(ValidationMixin(TICDForcedSystemMode, DynamoTable)) {

  constructor(dynamoDbClient) {
    super('ICDForcedSystemMode', 'icd_id', 'created_at', dynamoDbClient);
  }

  retrieveByIcdId(icdId) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': icdId
      }
    };
    return this.dynamoDbClient.query(params).promise();
  }

  retrieveLatestByIcdId(icdId) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': icdId
      },
      ScanIndexForward: false,
      Limit: 1
    };
    return this.dynamoDbClient.query(params).promise();
  }

}

export default new DIFactory(ICDForcedSystemModeTable, [AWS.DynamoDB.DocumentClient]);