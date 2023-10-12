import _ from 'lodash';
import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TEventChronology from './models/TEventChronology';

class FloDetectEventChronologyTable extends ValidationMixin(TEventChronology, DynamoTable) {
 constructor(dynamoDbClient) {
    super('FloDetectEventChronology', 'device_id_request_id', 'start', dynamoDbClient);
  }

  _normalizeData(data) {
    const { end } = data;

    return {
      ...data,
      ...(end ? { end: new Date(end).toISOString() } : {})
    };
  }

  _composeKeys(keys) {
    const { device_id, request_id, start } = keys;

    return {
      device_id_request_id: `${ device_id }_${ request_id }`,
      start: new Date(start).toISOString()
    };
  }

  _stripCompoundKeys(data) {
    return _.omit(data, ['device_id_request_id']);
  }

  marshal(data) {

    return super.marshal({
      ...this._normalizeData(data),
      ...this._composeKeys(data)
    });
  }

  marshalPatch(keys, data) {
    return super.marshalPatch(this._composeKeys(keys), this._normalizeData(data));
  }

  retrieve(keys) {
    return super.retrieve(this._composeKeys(keys))
      .then(result => ({
        ...result,
        Item: this._stripCompoundKeys(result.Item)
      }));
  }

  retrieveAfterStartDate(deviceId, requestId, startDate, pageSize = 50, isDescending = false) {
    const deviceIdRequestId = this._composeKeys({ 
      device_id: deviceId, 
      request_id: requestId,
      start: startDate
    }).device_id_request_id;
    const compare = isDescending ? '<' : '>';

    return this.dynamoDbClient.query({
      TableName: this.tableName,
      KeyConditionExpression: `#device_id_request_id = :device_id_request_id AND #start ${ compare } :start`,
      ExpressionAttributeNames: {
        '#device_id_request_id': 'device_id_request_id',
        '#start': 'start'
      },
      ExpressionAttributeValues: {
        ':device_id_request_id': deviceIdRequestId,
        ':start': startDate
      },
      Limit: pageSize,
      ScanIndexForward: !isDescending
    })
    .promise()
    .then(result => ({
      ...result,
      Items: result.Items.map(item => this._stripCompoundKeys(item))
    }));
  }
}

export default new DIFactory(FloDetectEventChronologyTable, [AWS.DynamoDB.DocumentClient]);