import _ from 'lodash';
import { directiveDataMap } from './models/directiveData';
import { rejectForcedSleep } from '../../../util/forcedSleep';
import { cancelPendingTasksByIcdId } from '../../../util/taskScheduler';
import DirectiveService from './DirectiveService';
import container from './container';

const directiveService = container.get(DirectiveService);

const defaultDirectiveHandlers = _.mapValues(
	directiveDataMap,
  (value, directive) => ((...args) => directiveService.sendDirective(directive, ...args))
);

function setSystemMode(icd_id, user_id, app_used, data) {
  const systemMode = data.mode;
  const systemModeName = systemMode == 2 ?
    'home' :
    systemMode == 3 ?
      'away' :
      systemMode == 5 ?
        'sleep' :
        'unknown';
        
	return rejectForcedSleep(icd_id)
    .then(() => directiveService.icdService.patch(icd_id, { target_system_mode: systemModeName }))
		.then(() => Promise.all([
      cancelPendingTasksByIcdId(icd_id, 'sleep'),
			defaultDirectiveHandlers['set-system-mode'](icd_id, user_id, app_used, data)
		]))
}

function closeValve(icd_id, user_id, app_used, data) {
  
  return directiveService.icdService.patch(icd_id, {
    target_valve_state: 'closed'
  })
  .then(() => defaultDirectiveHandlers['close-valve'](icd_id, user_id, app_used, data));
}

function openValve(icd_id, user_id, app_used, data) {

  console.log(defaultDirectiveHandlers['open-valve']);

  return directiveService.icdService.patch(icd_id, {
    target_valve_state: 'open'
  })
  .then(() => defaultDirectiveHandlers['open-valve'](icd_id, user_id, app_used, data));
}

export default {
	...defaultDirectiveHandlers,
	['set-system-mode']: setSystemMode,
  ['open-valve']: openValve,
  ['close-valve']: closeValve,
  retrieveDirectiveLogByDirectiveId: (...args) => directiveService.retrieveDirectiveLogByDirectiveId(...args)
};