import client from '../../util/dynamoUtil';
import _ from 'lodash';
import CachedDynamoTable from './cachedDynamoTable';

class ICDAlarmNotificationDeliveryRuleTable extends CachedDynamoTable {

  constructor() {
    super('ICDAlarmNotificationDeliveryRule', 'alarm_id', 'system_mode');
  }

  retrieveByAlarmId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'alarm_id = :alarm_id',
      ExpressionAttributeValues: {
        ':alarm_id': keys.alarm_id
      }
    };
    return client.query(params).promise();
  }

  retrieveBySystemModeSeverity({ system_mode, severity }) {
    const params = {
      TableName: this.tableName,
      IndexName: 'SystemModeIndex',
      KeyConditionExpression: 'system_mode = :system_mode',
      FilterExpression: 'severity = :severity',
      ExpressionAttributeValues: {
        ':system_mode': system_mode,
        ':severity': severity
      }
    };

    return client.query(params).promise();
  }
}

export default ICDAlarmNotificationDeliveryRuleTable;