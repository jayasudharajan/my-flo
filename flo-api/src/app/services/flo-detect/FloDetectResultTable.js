import _ from 'lodash';
import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TFloDetectResult from './models/TFloDetectResult';
import TStatus from './models/TStatus';
import moment from 'moment';
import ServiceException from '../utils/exceptions/ServiceException';

class FloDetectResultTable extends ValidationMixin(TFloDetectResult, DynamoTable)  {

  constructor(dynamoDbClient) {
    super('FloDetectResult', 'device_id', 'duration_in_seconds_start_date', dynamoDbClient);
  }

  composeKeys(data) {
    const normalizedData = this._normalizeData(data);
    const { device_id, start_date, end_date, duration_in_seconds } = normalizedData;
    const duration = duration_in_seconds || moment(end_date).diff(start_date, 'seconds');

    return {
      device_id,
      duration_in_seconds_start_date: `${ duration }_${start_date}`,
    };
  }

  _stripCompoundKeys(data) {
    return _.omit(data, ['duration_in_seconds_start_date', 'status_duration_in_seconds_start_date']);
  }

  _normalizeData(data) {
   const startDate = data.start_date && moment(data.start_date).toISOString();
   const endDate = data.end_date && moment(data.end_date).toISOString();
   
   return {
      ..._.omit(data, ['did', 'date_range']),
      ...(startDate ? { start_date: startDate } : {}),
      ...(endDate ? { end_date: endDate } : {})
    }; 
  }

  retrieve(keys) {
    return super.retrieve(keys)
      .then(result => ({
        ...result,
        Item: this._stripCompoundKeys(result.Item)
      }));
  }

  marshal(data) {
    const { start_date, end_date, status } = data;
    const normalizedData = this._normalizeData(data);
    const keys = this.composeKeys(normalizedData);
    const status_duration_in_seconds_start_date = `${ status }_${ keys.duration_in_seconds_start_date }`;

    return super.marshal({
      ...normalizedData,
      ...keys,
      status_duration_in_seconds_start_date
    });
  }

  marshalPatch(keys, data) {
    const { duration_in_seconds_start_date } = keys;
    const normalizedData = this._normalizeData(data);
    const { status } = normalizedData;

    const status_duration_in_seconds_start_date = status && {
      status_duration_in_seconds_start_date: `${ status }_${ duration_in_seconds_start_date }`
    };

    return super.marshalPatch(keys, {
        ...normalizedData,
        ...(status_duration_in_seconds_start_date || {})
    });
  }

  retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate) {
    const keys = this.composeKeys({ 
      device_id: deviceId,
      start_date: startDate,
      end_date: endDate
    });

    return this.retrieve(keys);
  }


  retrieveLatestByDeviceId(deviceId, duration) {
    const params = {
      TableName: this.tableName,
      IndexName: 'DeviceIdStatusDurationInSecondsStartDate',
      KeyConditionExpression: '#hash_key = :device_id AND begins_with(#range_key, :status_duration)',
      ExpressionAttributeValues: {
        ':device_id': deviceId,
        ':status_duration': `${ TStatus.executed }_${ duration }_`
      },
      ExpressionAttributeNames: {
        '#hash_key': 'device_id',
        '#range_key': 'status_duration_in_seconds_start_date' 
      },
      ScanIndexForward: false,
      Limit: 1
    };

    return this.dynamoDbClient.query(params).promise()
      .then(result => ({
        ...result,
        Items: result.Items.map(item => this._stripCompoundKeys(item))
      }));
  }

  retrieveLatestByDeviceIdInDateRange(deviceId, duration, rangeBeginDate, rangeEndDate) {
    const statusDuration = `${ TStatus.executed }_${ duration }`;

    const params = {
      TableName: this.tableName,
      IndexName: 'DeviceIdStatusDurationInSecondsStartDate',
      KeyConditionExpression: '#hash_key = :device_id AND #range_key BETWEEN :range_begin AND :range_end',
      ExpressionAttributeValues: {
        ':device_id': deviceId,
        ':range_begin': `${ statusDuration }_${ rangeBeginDate }`,
        ':range_end': `${ statusDuration }_${ rangeEndDate }`
      },
      ExpressionAttributeNames: {
        '#hash_key': 'device_id',
        '#range_key': 'status_duration_in_seconds_start_date' 
      },
      ScanIndexForward: false,
      Limit: 1 
    };

    return this.dynamoDbClient.query(params).promise()
      .then(result => ({
        ...result,
        Items: result.Items.map(item => this._stripCompoundKeys(item))
      }));
  }

  create(rawData) {
    return this.marshal(rawData)
      .then(data => {
        const statusIndex = TStatus.STATUS_ORDER.indexOf(data.status);
        const invalidStatus = statusIndex >= 0 && TStatus.STATUS_ORDER.slice(statusIndex);
        const ConditionExpression = invalidStatus && invalidStatus.map(status => `#status <> :${ status }`).join(' AND ');
        const ExpressionAttributeValues = invalidStatus && invalidStatus.reduce(
          (acc, status) => ({ ...acc, [`:${ status }`]: status }),
          {}
        );
        const condition = !invalidStatus ?
          {} :
          {
            ConditionExpression,
            ExpressionAttributeNames: {
              '#status': 'status'
            },
            ExpressionAttributeValues
          };

        return this.dynamoDbClient.put({
          TableName: this.tableName,
          Item: data,
          ...condition
        })
        .promise()
        .catch(err => {
          if (err.name === 'ConditionalCheckFailedException') {
            return Promise.reject(new ServiceException('Duplicate record.'));
          } else {
            return Promise.reject(err);
          }
        })
      }); 
  }
}

export default new DIFactory(FloDetectResultTable, [AWS.DynamoDB.DocumentClient]);