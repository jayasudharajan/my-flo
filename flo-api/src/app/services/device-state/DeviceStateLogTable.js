import DIFactory from '../../../util/DIFactory';
import AWS from 'aws-sdk';
import LogDynamoTable from '../../models/LogDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import TDeviceStateRequestLog from './models/TDeviceStateLog'

class DeviceStateLogTable extends ValidationMixin(TDeviceStateRequestLog, LogDynamoTable) {

  constructor(dynamoDbClient) {
    super('DeviceStateLog', 'device_id', 'created_at', dynamoDbClient);
  }
}

export default new DIFactory(DeviceStateLogTable, [AWS.DynamoDB.DocumentClient]);