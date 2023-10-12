import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';
import LogDynamoTable from '../../models/LogDynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TFixtureDetectionLog from './models/TFixtureDetectionLog';
import TStatus from './models/TStatus';

class FixtureDetectionLogTable extends ValidationMixin(TFixtureDetectionLog, LogDynamoTable)  {

  constructor(dynamoDbClient) {
    super('FixtureDetectionLog', 'request_id', 'created_at', dynamoDbClient);
  }

  composeKeys({ start_date, end_date, status }) {
    return {
      start_date_end_date_status: `${start_date}_${end_date}_${status}`,
    };
  }

  marshal(data) {
    return super.marshal({
      ...data,
      ...this.composeKeys(data)
    });
  }

  retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate) {
    const params = {
      TableName: this.tableName,
      IndexName: 'start_and_end_date_with_status_index',
      KeyConditionExpression: 'device_id = :hash_key AND start_date_end_date_status = :range_key',
      ExpressionAttributeValues: {
        ':hash_key': deviceId,
        ':range_key': `${startDate}_${endDate}_${TStatus.executed}`
      },
      ScanIndexForward: false,
      Limit: 1
    };

    return this.dynamoDbClient.query(params).promise();
  }

  retrieveLatestByDeviceId(deviceId) {
    const params = {
      TableName: this.tableName,
      IndexName: 'DeviceIdCreatedAtIndex',
      KeyConditionExpression: 'device_id = :hash_key',
      FilterExpression: '#status = :status',
      ExpressionAttributeValues: {
        ':hash_key': deviceId,
        ':status':  TStatus.executed
      },
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ScanIndexForward: false,
      Limit: 1
    };

    return this.dynamoDbClient.query(params).promise();
  }
}

export default new DIFactory(FixtureDetectionLogTable, [AWS.DynamoDB.DocumentClient]);