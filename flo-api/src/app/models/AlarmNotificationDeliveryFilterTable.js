import client from '../../util/dynamoUtil';
import _ from 'lodash';
import moment from 'moment';
import DynamoTable from './DynamoTable';
import ICDAlarmNotificationDeliveryRuleTable from '../models/ICDAlarmNotificationDeliveryRuleTable';
import ICDAlarmIncidentRegistryTable from '../models/ICDAlarmIncidentRegistryTable';

let ICDAlarmNotificationDeliveryRule = new ICDAlarmNotificationDeliveryRuleTable();
let ICDAlarmIncidentRegistry = new ICDAlarmIncidentRegistryTable();

let expirationLimit = 60;  // minutes

class AlarmNotificationDeliveryFilterTable extends DynamoTable {

  constructor() {
    super('AlarmNotificationDeliveryFilter', 'icd_id', 'alarm_id_system_mode');
  }

  retrieveByICDId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      }
    };
    return client.query(params).promise();
  }

  retrieveByICDIdAlarmId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id AND begins_with (alarm_id_system_mode, :alarm_id)',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id,
        ':alarm_id': keys.alarm_id
      }
    };
    return client.query(params).promise();
  }

  retrieveByICDIdStatus(keys) {
    let indexName = "ICDIdStatusIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'icd_id = :icd_id AND #status = :status',
      ExpressionAttributeNames: { "#status": "status" },
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id,
        ':status': keys.status
      }
    };
    return client.query(params).promise();
  }

  // Fetch AlarmNotificationDeliveryFilter by icd and status=3 (unresolved).
  // Order by severity and incident_time.
  // Get top one.
  // Fetch ICDAlarmIncidentRegistry and combine with ICDAlarmNotificationDeliveryRule.
  retrieveHighestSeverityByICDId(keys) {

    return this.retrieveByICDIdStatus({ icd_id: keys.icd_id, status: 3 })
      .then(alarmFilters => {
        // Remove any ZIT related alarms.
        // Find and remove items with severity of 3.  (All ZIT)
        const alarm = _.chain(alarmFilters.Items)
          .filter(({ severity }) => severity < 3)
          .orderBy(['incident_time'], ['desc'])
          .minBy('severity')
          .update('alarm_id', alarm_id => parseInt(alarm_id, 10))
          .update('system_mode', system_mode => parseInt(system_mode, 10))
          .value();

        // TODO: check for null alarm values.            
        // Retrieve and combine the Incident and Delivery Rule.
        return !alarm ? {} : Promise.all([
          ICDAlarmIncidentRegistry.retrieve({ id: alarm.last_icd_alarm_incident_registry_id }), 
          ICDAlarmNotificationDeliveryRule.retrieve({ alarm_id: alarm.alarm_id , system_mode: alarm.system_mode })
        ])
        .then(([incidentResult, deliveryRuleResult]) => {

          if(_.isEmpty(incidentResult.Item)) {
            return new Promise((resolve, reject) => {
              reject({ status: 404, message: "Incident from filter not found." });
            });
          } else if(_.isEmpty(deliveryRuleResult.Item)) {
            return new Promise((resolve, reject) => {
              reject({ status: 404, message: "Matching delivery rule not found." });
            });
          } 
          
          return _.extend(
            {},
            _.pick(alarm, ['system_mode']),
            _.pick(deliveryRuleResult.Item, ['friendly_name', 'friendly_description', 'user_actions', 'extra_info']),
            incidentResult.Item
          );
        });
    });
  }

  retrieveStatusByICDId({ icd_id, status, offset, descending }) {
    const indexName = 'ICDIdIncidentTimeIndex';
    const params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'icd_id = :icd_id',
      FilterExpression: '#status = :status',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':icd_id': icd_id,
        ':status': status
      },
      ExclusiveStartKey: offset || undefined,
      ScanForwardIndex: !descending
    };

    return client.query(params).promise();
  }
}

export default AlarmNotificationDeliveryFilterTable;
