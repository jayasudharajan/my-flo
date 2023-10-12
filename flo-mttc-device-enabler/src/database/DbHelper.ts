import _ from 'lodash';
import moment from 'moment';
import { MicroLeakTestTimeRecord } from '../interfaces';
import DynamoDbClient from './dynamo/DynamoDbClient';

class DbHelper {
  constructor(
    private dynamoDbClient: DynamoDbClient
  ) {}

  public async isMttcOverridenByAdmin(deviceId: string): Promise<boolean> {
    const mttcRecord = _.first(await this.dynamoDbClient.query<MicroLeakTestTimeRecord>('MicroLeakTestTime', {
      KeyConditionExpression: '#device_id = :device_id',
      ScanIndexForward: false,
      Limit: 1,
      ExpressionAttributeNames: {
        '#device_id': 'device_id'
      },
      ExpressionAttributeValues: {
        ':device_id': deviceId
      }
    }));

    return (
      !_.isNil(mttcRecord) &&
      !_.isNil(mttcRecord.reference_time) &&
      moment(mttcRecord.reference_time.data_start_date).isSame(moment(0))
    );
  }
}

export default DbHelper;