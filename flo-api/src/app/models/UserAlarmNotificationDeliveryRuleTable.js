import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class UserAlarmNotificationDeliveryRuleTable extends DynamoTable {

  constructor() {
    super('UserAlarmNotificationDeliveryRule', 'user_id', 'location_id_alarm_id_system_mode');
  }

  retrieveByUserId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': keys.user_id
      }
    };
    return client.query(params).promise();
  }

  // Gets all the alarm preferences for a User for a given Location.
  retrieveByUserIdLocationId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id AND begins_with (location_id_alarm_id_system_mode, :location_id)',
      ExpressionAttributeValues: {
        ':user_id': keys.user_id,
        ':location_id': keys.location_id,
      }
    };
    return client.query(params).promise();
  }

  // Gets alarm preferences for all Users for a given Location/Alarm type.
  retrieveByLocationIdAlarmId(keys) {
    // NOTE: concat of location_id + alarm_id.
    let params = {
      TableName: this.tableName,
      IndexName: 'LocationIdAlarmIdIndex',
      KeyConditionExpression: 'location_id = :location_id AND alarm_id = :alarm_id',
      ExpressionAttributeValues: {
        ':location_id': keys.location_id,
        ':alarm_id': keys.alarm_id
      }
    };

    return client.query(params).promise();
  }

  retrieveByLocationIdAlarmIdSystemMode(keys) {
    // NOTE: concat of location_id + alarm_id + system_mode.
    // Return multiple users.
    let params = {
      TableName: this.tableName,
      IndexName: 'LocationIdAlarmIdSystemModeIndex',
      KeyConditionExpression: 'location_id_alarm_id_system_mode = :location_id_alarm_id_system_mode',
      ExpressionAttributeValues: {
        ':location_id_alarm_id_system_mode': keys.location_id + "_" + keys.alarm_id + "_" + keys.system_mode
      }
    };

    return client.query(params).promise();
  }

}

export default UserAlarmNotificationDeliveryRuleTable;
