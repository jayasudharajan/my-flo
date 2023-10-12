import axios from 'axios';
import config from '../config';
import { EntityActivityMessage, IncidentStatus } from '../interfaces';

const isTriggered = (msg: EntityActivityMessage): boolean => {
  return msg.item.status === IncidentStatus.TRIGGERED;
};


export const notify = async (msg: EntityActivityMessage): Promise<void> => {

  if (!isTriggered(msg)) {
    return;
  }

  const severity = mapSeverity(msg.item.alarm.severity);

  if (!severity) {
    console.log(`Dropping message with unknown status => ${JSON.stringify(msg)}`);
    return;
  }
  
  const alertData = {
    deviceId: msg.item.device.id,
    severity
  }

  console.log(`Forwarding alert => ${JSON.stringify(alertData)}`);

  await axios({
    method: 'POST',
    url: `${ config.apiUrl }${ config.iftttAlertEndpoint }`,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': config.apiToken
    },
    data: alertData
  });
}

function mapSeverity(severity: string): number | null {

  switch (severity.toLowerCase()) {
    case 'critical':
      return 1;
    case 'warning':
      return 2;
    case 'info':
      return 3;
    default:
      return null;
  }
}