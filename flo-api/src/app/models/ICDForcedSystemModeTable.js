import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class ICDForcedSystemModeTable extends DynamoTable {

  constructor() {
    super('ICDForcedSystemMode', 'icd_id', 'created_at');
  }

  retrieveByIcdId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      }
    };
    return client.query(params).promise();
  }

  retrieveLatestByIcdId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      },
      ScanIndexForward: false,
      Limit: 1
    };
    return client.query(params).promise();
  }

}

export default ICDForcedSystemModeTable;