import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TAccountGroupAlarmNotificationDeliveryRule from './models/TAccountGroupAlarmNotificationDeliveryRule';

class AccountGroupAlarmNotificationDeliveryRuleTable extends ValidationMixin(TAccountGroupAlarmNotificationDeliveryRule, DynamoTable) {

  constructor(dynamoDbClient) {
    super(
      'AccountGroupAlarmNotificationDeliveryRule',
      'group_id',
      'alarm_id_system_mode_user_role',
      dynamoDbClient
    );
  }

  generateCompoundKey({ alarm_id, system_mode, user_role }) {
    return alarm_id && system_mode && user_role ?
      { 
        alarm_id_system_mode_user_role: `${ alarm_id }_${ system_mode }_${ user_role }`,
      } :
      {};
  }

  stripCompoundKey(data) {
    return data && _.omit(data, ['alarm_id_system_mode_user_role']);
  }

  retrieve(...keys) {

    return super.retrieve(...keys)
      .then(result => ({ 
        ...result,
        Item: this.stripCompoundKey(result.Item)
      }));
  }

  marshal(data) {

    return super.marshal({
      ...data,
      ...this.generateCompoundKey(data)
    });
  }

  marshalPatch(keys, data) {
    return super.marshalPatch(keys, _.omit(data, [
      'alarm_id',
      'system_mode',
      'user_role'
    ]));
  }

  retrieveByGroupId(groupId) {
    return this.dynamoDbClient.query({
      TableName: this.tableName,
      KeyConditionExpression: 'group_id = :group_id',
      ExpressionAttributeValues: {
        ':group_id': groupId
      }
    })
    .promise()
    .then(result => ({
      ...result,
      Items: result.Items.map(item => this.stripCompoundKey(item))
    }));
  }

  retrieveByGroupIdAlarmIdSystemMode(groupId, alarmId, systemMode) {
    return this.dynamoDbClient.query({
      TableName: this.tableName,
      KeyConditionExpression: 'group_id = :group_id AND begins_with(alarm_id_system_mode_user_role, :alarm_id_system_mode)',
      ExpressionAttributeValues: {
        ':group_id': groupId,
        ':alarm_id_system_mode': `${ alarmId }_${ systemMode }`
      }
    })
    .promise()
    .then(result => ({
      ...result,
      Items: result.Items.map(item => this.stripCompoundKey(item))
    }));
  }
}

export default new DIFactory(AccountGroupAlarmNotificationDeliveryRuleTable, [AWS.DynamoDB.DocumentClient]);