import _ from 'lodash';
import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TFixtureAverage from './models/TFixtureAverage';

class FloDetectFixtureAverageTable extends ValidationMixin(TFixtureAverage, DynamoTable)  {

  constructor(dynamoDbClient) {
    super('FloDetectFixtureAverage', 'device_id', 'duration_in_seconds_start_date', dynamoDbClient);
  }

  composeKeys(data) {
    const { device_id, start_date, end_date, duration_in_seconds } = data;
    const duration = duration_in_seconds || moment(end_date).diff(start_date, 'seconds');

    return {
      device_id,
      duration_in_seconds_start_date: `${ duration }_${start_date}`,
    };
  }

  _stripCompoundKeys(data) {
    return _.omit(data, ['duration_in_seconds_start_date']);
  }

  marshal(data) {
    const keys = this.composeKeys(data);

    return super.marshal({
      ...data,
      ...keys
    });
  }

  retrieve(keys) {
    return super.retrieve(keys)
      .then(result => ({
        ...result,
        Item: this._stripCompoundKeys(result.Item)
      }));
  }

  retrieveLatest(deviceId, duration) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: '#hash_key = :device_id AND begins_with(#range_key, :duration)',
      ExpressionAttributeValues: {
        ':device_id': deviceId,
        ':duration': `${ duration }`
      },
      ExpressionAttributeNames: {
        '#hash_key': 'device_id',
        '#range_key': 'duration_in_seconds_start_date' 
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
}

export default new DIFactory(FloDetectFixtureAverageTable, [AWS.DynamoDB.DocumentClient]);