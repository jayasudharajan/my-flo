import DIFactory from '../../../util/DIFactory';
import AWS from 'aws-sdk';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TDeviceAnomalyEvent from './models/TDeviceAnomalyEvent';
import _ from 'lodash';

class DeviceAnomalyEventTable extends ValidationMixin(TDeviceAnomalyEvent, DynamoTable) {

  constructor(dynamoDbClient) {
    super('DeviceAnomalyEvent', 'device_id', 'time', dynamoDbClient);
  }

  marshal(data) {
    const {type, device_id, time} = data;
    const time_device_id = `${ time }_${ device_id }`;

    return super.marshal({
      ...data,
      time_device_id
    });
  }

  _stripCompoundKeys(data) {
    return _.omit(data, ['time_device_id']);
  }

  retrieve(keys) {
    return super.retrieve(keys)
      .then(result => ({
        ...result,
        Item: this._stripCompoundKeys(result.Item)
      }));
  }
  
  retrieveByEventTypeAndTime(type, startTime, endTime) {
    const params = {
      TableName: this.tableName,
      IndexName: 'DeviceAnomalyEventTypeTimeIndex',
      KeyConditionExpression: '#type = :type AND #time_device_id BETWEEN :start_time AND :end_time',
      ExpressionAttributeNames: {
        '#type': 'type',
        '#time_device_id': 'time_device_id'
      },
      ExpressionAttributeValues: {
        ':type': type,
        ':start_time': startTime,
        ':end_time': endTime
      }
    };
    return this.dynamoDbClient.query(params).promise()
      .then(result => ({
        ...result,
        Items: result.Items.map(item => this._stripCompoundKeys(item))
      }));
  }
}

export default new DIFactory(DeviceAnomalyEventTable, [AWS.DynamoDB.DocumentClient]);