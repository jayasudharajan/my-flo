import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import TDeviceSerialNumber from './models/TDeviceSerialNumber'
import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';

class DeviceSerialNumberTable extends ValidationMixin(TDeviceSerialNumber, DynamoTable)  {
  constructor(dynamoDbClient) {
    super('DeviceSerialNumber', 'device_id', undefined, dynamoDbClient);
  }

  remove(deviceId) {
    return this.dynamoDbClient.delete({
      TableName: this.tableName,
      Key: {
        device_id: deviceId
      },
      ConditionExpression: 'attribute_exists(#device_id)',
      ExpressionAttributeNames: {
        '#device_id': 'device_id'
      }
    })
    .promise();
  }

  retrieveBySerialNumber(serialNumber) {
    return this.dynamoDbClient.query({
      TableName: this.tableName,
      IndexName: 'SerialNumber',
      KeyConditionExpression: '#sn = :sn',
      ExpressionAttributeNames: {
        '#sn': 'sn'
      },
      ExpressionAttributeValues: {
        ':sn': serialNumber
      }
    })
    .promise();
  }

  createUnique(data) {
    return this.dynamoDbClient.put({
      TableName: this.tableName,
      Item: data,
      // Only allow if device ID does not already have serial number
      ConditionExpression: 'attribute_not_exists(#device_id)',
      ExpressionAttributeNames: {
        '#device_id': 'device_id'
      }
    })
    .promise();
  }
}

export default new DIFactory(DeviceSerialNumberTable, [AWS.DynamoDB.DocumentClient]);