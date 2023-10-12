import _ from 'lodash';
import { lookupByDeviceId } from './icdUtils';
import { getTimezoneByLocationId } from './locationUtils';
import ExternalActionLogTable from '../app/models/ExternalActionLogTable';

const ExternalActionLog = new ExternalActionLogTable();

export function handleExternalAction({ user_id, device_id, action_id, log }) { 

  return lookupByDeviceId(device_id, log)
    .then(({ id: icd_id, location_id }) => logExternalAction({ user_id, device_id, action_id, icd_id }));
}

function logExternalAction({ user_id, device_id, action_id, icd_id }) {
  const params = _.omitBy({ user_id, device_id, action_id, icd_id }, val => !val);
  return ExternalActionLog.createLatest(params);
}
