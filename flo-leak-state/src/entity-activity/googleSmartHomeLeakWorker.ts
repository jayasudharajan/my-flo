import axios from 'axios';
import moment from 'moment';
import config from '../config';
import { EntityActivityMessage, IncidentStatus } from '../interfaces';

const isTriggered = (msg: EntityActivityMessage): boolean => {
  return msg.item.status === IncidentStatus.TRIGGERED;
};

const isResolved = (msg: EntityActivityMessage): boolean => {
  return msg.item.status === IncidentStatus.RESOLVED;
};

export const report = async (msg: EntityActivityMessage): Promise<void> => {
  let leakState = -1;
  if (isTriggered(msg)) {
    leakState = 1;
  } else if (isResolved(msg)) {
    leakState = 0;
  }

  const stateData = {
    id: msg.id,
    sn: 'leak-state',
    did: msg.item.device.macAddress,
    st: leakState,
    ts: Math.floor(moment.utc(msg.item.updateAt).valueOf() / 1000)
  }

  console.log(`Reporting state => ${JSON.stringify(stateData)}`);

  await axios({
    method: 'POST',
    url: `${ config.apiUrl }${ config.reportStateEndpoint }`,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': config.apiToken
    },
    data: stateData
  });
}