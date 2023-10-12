import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class ICDAlarmNotificationStatusRegistryTable extends DynamoTable {

  constructor() {
    super('ICDAlarmNotificationStatusRegistry', 'id');
  }

  retrieveByIcdId(keys) {
    let params = {
      TableName: this.tableName,
      IndexName: 'icd_id',
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      }
    };
    return client.query(params).promise();
  }

  retrieveByIcdIdAndIncidentTime(keys) {
    let params = {
      TableName: this.tableName,
      IndexName: 'icd_id',
      KeyConditionExpression: 'icd_id = :icd_id AND incident_time = :incident_time',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id,
        ':incident_time': keys.incident_time
      }
    };
    return client.query(params).promise();
  }

  retrieveByIcdAlarmIncidentRegistryId(keys) {
    let params = {
      TableName: this.tableName,
      IndexName: 'icd_alarm_incident_registry_id',
      KeyConditionExpression: 'icd_alarm_incident_registry_id = :icd_alarm_incident_registry_id',
      ExpressionAttributeValues: {
        ':icd_alarm_incident_registry_id': keys.icd_alarm_incident_registry_id
      }
    };
    return client.query(params).promise();
  }

  retrieveByIcdAlarmIncidentRegistryIdAndIncidentTime(keys) {
    let params = {
      TableName: this.tableName,
      IndexName: 'icd_alarm_incident_registry_id',
      KeyConditionExpression: 'icd_alarm_incident_registry_id = :icd_alarm_incident_registry_id AND incident_time = :incident_time',
      ExpressionAttributeValues: {
        ':icd_alarm_incident_registry_id': keys.icd_alarm_incident_registry_id,
        ':incident_time': keys.incident_time
      }
    };
    return client.query(params).promise();
  }
}

export default ICDAlarmNotificationStatusRegistryTable;