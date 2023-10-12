#!/usr/bin/env node
import config from './config';
import axios from 'axios';
import AWS, { DynamoDB } from 'aws-sdk';
import _ from 'lodash';
import { Client } from 'pg';
import DynamoDbClient from './database/dynamo/DynamoDbClient';
import format from 'pg-format';
import moment from 'moment-timezone';

axios.defaults.headers.common['Authorization'] = config.apiToken;

AWS.config.update({
  region: config.awsRegion
});

//In V2
const Filtered = 2;
const Triggered = 3;
const Resolved = 4;

const DndNoMediumAllowed = 5;
const Cleared = 8;
const Snoozed = 9;
const Internal = 10;
const Expired = 12;
const ValveClosed = 17;
const DefaultReason = 0;

const RegistryLogStatus = {
  NONE: 1,
  TRIGGERED: 2,
  SENT: 3,
  DELIVERED: 4,
  FAILED: 5,
  OPENED: 6,
  BOUNCE: 7,
  DROPPED: 8,
  GRAVEYARDFILTERED: 9,
  CLOSEDVALVEFILTERED: 10,
  TIMEELAPSEDSINCEINCIDENTISTOOMUCH: 11,
  MUTEDBYUSER: 12
}


const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);

const from = '2019-09-22';
const to = '2019-10-24';
const filter = 'created_at >= :from AND created_at <= :to';
const expressionValues = {
  ':from': from,
  ':to': to,
};

console.log('Migration started');

const fields = '(id, alarm_id, icd_id, status, snooze_to, location_id, system_mode, update_at, create_at, reason, account_id, data_values, display_title, display_message, display_locale)';



dynamoDbClient.scanBatchWithFilter('ICDAlarmIncidentRegistry', filter, expressionValues, (incidents: any[]) => {
  if(!_.isEmpty(incidents)) {
    Promise.all(incidents.map(x => buildIncidentData(x))).then(items => {
      const client = new Client();

      client.connect();

      const insertQuery = format(`INSERT INTO incidents_to_migrate ${fields} VALUES %L`, items);

      //Store it with the same schema that incidents cos we will source from just 1 Dynamo table
      client.query(insertQuery, (err: any) => {
        if(err) {
          console.log(err);
        }

        client.end();
      });
    }).catch(console.log);
  }
}, () => {
  console.log('Starting the clear phase!!!');

  let migrationFinished = false;

  const client = new Client();
  client.connect();

  const itemsCountQuery = `SELECT COUNT (*) FROM (
    SELECT DISTINCT ON (incident.icd_id, incident.alarm_id) *
        FROM incidents_to_migrate as incident
        WHERE reason = 8 OR reason = 9
        ORDER BY incident.icd_id, incident.alarm_id, create_at DESC
    ) as temp;
  `;
  client
    .query(itemsCountQuery)
    .then(res => {
      const totalCount = res.rows[0].count;

      client.end();

      return processAllClearOrSnoozePaginated(totalCount, 100);
    })
    .then(() => {
      return moveAllTheIncidentsToFinalTable();
    })
    .then(() => {
      migrationFinished = true;
    })
    .catch(e => console.error(e.stack));

  function waiTilFinished() {
    if(!migrationFinished) setTimeout(waiTilFinished, 3000)
  }

  waiTilFinished();
});

function moveAllTheIncidentsToFinalTable(): Promise<any> {
  return deleteRangeDateIncidentsOfFinalTable(from, to)
    .then(() => moveFromTempTableToFinal());
}

function moveFromTempTableToFinal(): Promise<any> {
  const client = new Client();
  const moveQuery = 'INSERT INTO incident SELECT * FROM incidents_to_migrate';

  client.connect();

  return client.query(moveQuery).then(() => client.end());
}

function deleteRangeDateIncidentsOfFinalTable(from: string, to: string): Promise<any> {
  const client = new Client();
  const deleteQuery = `DELETE FROM incident WHERE create_at >= '${from}' AND create_at <= '${to}'`;

  client.connect();

  return client.query(deleteQuery).then(() => client.end());
}

function processAllClearOrSnoozePaginated(totalCount: number, pageSize: number): Promise<any> {
  const pages = totalCount % pageSize > 0 ? Math.floor(totalCount / pageSize) + 1 : Math.floor(totalCount / pageSize);
  const zeroBasedPages = pages > 0 ? pages - 1 : 0;

  return _processAllClearOrSnoozePaginated(zeroBasedPages, pageSize);
}


function _processAllClearOrSnoozePaginated(currentPage: number, pageSize: number): Promise<any> {
  if(currentPage < 0) {
    return Promise.resolve({});
  }

  console.log(`Resolving alarms of page ${currentPage}`);

  const offset = currentPage * pageSize;
  const limit = pageSize;

  const itemsQuery = `SELECT DISTINCT ON (incident.icd_id, incident.alarm_id) *
    FROM incidents_to_migrate as incident
    WHERE reason = 8 OR reason = 9
    ORDER BY incident.icd_id, incident.alarm_id, create_at DESC
    LIMIT ${limit}
    OFFSET ${offset}
  `;

  const client = new Client();
  client.connect();

  return client.query(itemsQuery).then(({ rows } )=> {
    client.end();

    const promises = Promise.all([rows.map(incident => {
      const alarmId = incident.alarm_id;
      const icdId = incident.icd_id;
      const offset = moment().utcOffset();
      const createdAt = moment(incident.create_at).utc().add(offset, 'minutes');

      const updateQuery = `UPDATE incidents_to_migrate 
        SET status=${Resolved} 
        WHERE status=${Triggered} AND icd_id = '${icdId}' AND alarm_id = ${alarmId} AND create_at < '${createdAt.toISOString().replace('Z', '').replace('T', ' ')}'
      `;

      const client = new Client();
      client.connect();

      return client.query(updateQuery).then(() => client.end());
    })]);

    return promises.then(() => {
      console.log(`Alarms of page ${currentPage} RESOLVED!!!`);
      return _processAllClearOrSnoozePaginated(currentPage - 1, pageSize);
    });
  });
}

async function buildIncidentData(incident: any) {
  const logEntriesForIncident = await dynamoDbClient.query('ICDAlarmIncidentRegistryLog', {
    KeyConditionExpression: 'icd_alarm_incident_registry_id = :hkey',
    ExpressionAttributeValues: {
      ':hkey': incident.id
    }
  });
  const filter = await dynamoDbClient.get('AlarmNotificationDeliveryFilter', {
    "icd_id": incident.icd_data.id,
    "alarm_id_system_mode": `${incident.alarm_id}_${incident.icd_data.system_mode}`
  });

  const tentativeStatus = getStatus(incident, logEntriesForIncident, filter);
  const snoozeTo = getSnoozeTo(incident);
  const reason = getReason(incident, logEntriesForIncident, snoozeTo, tentativeStatus);
  const finalStatus = (snoozeTo || reason == Cleared) ? Resolved : tentativeStatus;

  return [
    incident.id,
    incident.alarm_id,
    incident.icd_id,
    finalStatus,
    snoozeTo,
    incident.location_id,
    incident.telemetry_data.sm || incident.icd_data.system_mode,
    incident.created_at,
    incident.created_at,
    reason,
    incident.account_id,
    incident.telemetry_data,
    incident.friendly_name,
    incident.friendly_description,
    ''
  ];
}

function getStatus(incident: any, incidentLogs: any, filter: any) {
  if(incident.acknowledged_by_user == 1) {
    return Resolved;
  }

  const actionId = _.get(incident, 'user_action_taken.action_id', 0);

  if(actionId == 4 || actionId == 5 || (actionId >= 7 && actionId <= 15)) {
    return Resolved;
  }

  const logOrdered = _.orderBy(incidentLogs, ['created_at'], ['desc']);

  if(!_.isEmpty((logOrdered))) {
    const lastLog = logOrdered[0];

    if(lastLog.delivery_medium > 1 && (lastLog.status >= RegistryLogStatus.TRIGGERED && lastLog.status <= RegistryLogStatus.DROPPED)) {
      const filterExpiresAt = _.get(filter, 'expires_at', null);

      if(filterExpiresAt && filterExpiresAt >= incident.created_at) {
        return Resolved;
      } else {
        return Triggered;
      }
    } else {
      return Filtered;
    }
  } else {
    return Filtered;
  }
}


function getSnoozeToFromActionId(executionTime: any, actionId: number) {
  switch(actionId) {
    case 1:
      return executionTime.add(2, 'hours').toISOString();
    case 2:
      return executionTime.add(2, 'hours').tz('America/Los_Angeles').endOf('day').utc().toISOString();
    case 3:
      return executionTime.add(100, 'years').toISOString();
    case 6:
      return executionTime.add(24, 'hours').toISOString();
    case 16:
      return executionTime.add(1, 'week').toISOString();
    case 18:
      return executionTime.add(30, 'days').toISOString();
    default:
      return null;
  }
}

function getReason(incident: any, incidentLogs: any, snoozeTo: any, finalStatus: number) {
  if(incident.alarm_id >= 5000) {
    return Internal;
  }

  if(snoozeTo) {
    return Snoozed;
  }

  const actionId = _.get(incident, 'user_action_taken.action_id', 0);

  if(actionId == 4) {
    return Cleared;
  }

  const logOrdered = _.orderBy(incidentLogs, ['created_at'], ['desc']);

  if(!_.isEmpty((logOrdered))) {
    const lastLog = logOrdered[0];

    if(lastLog.status == 10 || (finalStatus == Filtered && _.includes([7, 8, 9, 10, 15, 17], actionId))) {
      return ValveClosed;
    }

    if(lastLog.status == 9) {
      return DndNoMediumAllowed;
    }

    if(lastLog.status == 11) {
      return Expired;
    }
  }

  return DefaultReason;
}

function getSnoozeTo(incident: any) {
  const actionTaken = incident.user_action_taken;

  if(!_.isEmpty(actionTaken)) {
    const executionTime = moment.utc(actionTaken.execution_time);

    return getSnoozeToFromActionId(executionTime, actionTaken.action_id)
  } else {
    return null;
  }
}

