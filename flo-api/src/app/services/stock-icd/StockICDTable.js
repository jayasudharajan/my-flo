import EncryptedDynamoTable from '../../models/EncryptedDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import TStockICD from './models/TStockICD'
import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';
import EncryptionStrategy from '../utils/EncryptionStrategy';

class StockICDTable extends ValidationMixin(TStockICD, EncryptedDynamoTable)  {

  constructor(dynamoDbClient, encryptionStrategy) {
    if(typeof dynamoDbClient === 'undefined') {
      throw new Error('dynamoDbClient is required in StockICDTable.')
    }
    
    super(
      'StockICD',
      'id',
      undefined,
      [
        'icd_client_key',
        'icd_client_cert',
        'icd_login_token',
        'icd_websocket_cert',
        'icd_websocket_cert_der',
        'icd_websocket_key',
        'wifi_password',
        'ssh_private_key'
      ],
      dynamoDbClient,
      encryptionStrategy
    );
  }

  retrieveByDeviceId(keys) {
    let params = {
      TableName: this.tableName,
      IndexName: 'DeviceId',
      KeyConditionExpression: 'device_id = :device_id',
      ExpressionAttributeValues: {
        ':device_id': keys.device_id
      }
    };
    return this.decryptQuery(this.dynamoDbClient.query(params).promise());
  }
}

export default new DIFactory(StockICDTable, [ AWS.DynamoDB.DocumentClient, EncryptionStrategy]);