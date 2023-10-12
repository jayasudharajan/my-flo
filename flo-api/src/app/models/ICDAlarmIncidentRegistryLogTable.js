import client from '../../util/dynamoUtil';
import _ from 'lodash';
import moment from 'moment';
import uuid from 'node-uuid';
import DynamoTable from './DynamoTable';
import { deliveryMedium, deliveryStatus, deliveryFilterStatus,
         sendGridEvent, convertEmailStatus } from '../../util/enums';


class ICDAlarmIncidentRegistryLogTable extends DynamoTable {

  constructor() {
    super('ICDAlarmIncidentRegistryLog', 'icd_alarm_incident_registry_id', 'delivery_medium_status');
  }

  createRange(delivery_medium, status) {
    if(!delivery_medium) { delivery_medium = 0 };  // have defaults?
    if(!status) { status = 0 };
    return parseInt(delivery_medium.toString() + status.toString());
  }

  /**
   * Create an item.
   */
  create(data) {

    // Check range key, if exists in table.
    if(!data[this.keyName]) {
      return new Promise((resolve, reject) => {
        reject({ statusCode: 401, message: 'Incident ID required.'})
      });
    }
    if(!data.delivery_medium) {
      return new Promise((resolve, reject) => {
        reject({ statusCode: 401, message: 'delivery_medium required.'})
      });
    }
    if(!data.status) {
      return new Promise((resolve, reject) => {
        reject({ statusCode: 401, message: 'status required.'})
      });
    }

    data.delivery_medium_status = parseInt(data.delivery_medium.toString() + data.status.toString());
    data.unique_id = uuid.v4();
    data.created_at = moment().toISOString();

    let params = {
      TableName: this.tableName,
      Item: data
    };

    return client.put(params).promise()
      .then(result => {
        // Return back the item with id.
        if(_.isEmpty(result)) {
          return new Promise((resolve, reject) => {
            resolve(data);
          });
        } else {
          return new Promise((resolve, reject) => {
            reject({ message: "Unable to create item."})
          });
        }
      });

  }

  // Logs incident status by cloning an existing entry.
  logStatus(data) {

    return this.retrieveByReceiptId({ receipt_id: data.receipt_id })
      .then(incidentLog => {

        if(!_.isEmpty(incidentLog.Items)) {

          // Sort for most recent entry if multiple.
          let items = [];
          if(incidentLog.Items.length > 1) {
            items = _.orderBy(incidentLog.Items, ['created_at'], ['desc']);
          } else {
            items = incidentLog.Items;
          }

          // Clone and clean most recent log item.
          let logItem = _.clone(items[0]);
          delete logItem.unique_id;
          delete logItem.created_at;

          // Modify status.
          // TODO: account for not accepted status.
          let newStatus = deliveryStatus[sendGridEvent[data.event]];  // convert the status from SendGrid.
          logItem.status = newStatus;
          logItem.delivery_medium_status = this.createRange(deliveryMedium.email, newStatus);

          return this.create(logItem);

        } else {
          return new Promise((resolve, reject) => { 
            reject({ statusCode: 404, message: "No ICDAlarmIncidentRegistryLog found." }) 
          });
        }

      });

  }

  retrieveByIncidentId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'icd_alarm_incident_registry_id = :icd_alarm_incident_registry_id',
      ExpressionAttributeValues: {
        ':icd_alarm_incident_registry_id': keys.icd_alarm_incident_registry_id
      }
    };
    return client.query(params).promise();
  }

  retrieveByReceiptId(keys) {
    let params = {
      IndexName: 'ReceiptIdIndex',
      TableName: this.tableName,
      KeyConditionExpression: 'receipt_id = :receipt_id',
      ExpressionAttributeValues: {
        ':receipt_id': keys.receipt_id
      }
    };
    return client.query(params).promise();
  }


}

export default ICDAlarmIncidentRegistryLogTable;
