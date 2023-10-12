import config from '../config';
import axios from 'axios';
import GatewayService from "../GatewayService";
import moment from 'moment-timezone';

axios.defaults.headers.common['Authorization'] = config.apiToken;

const gatewayService = new GatewayService();

const USER_ACTION = {
  // _DD = from notifications view user action drop down menu
  // _NVS = from notifications view slider control
  // _CPS = from control panel slider control
  // _WEB = from website (user portal, etc.)
  IGNORE_2_HOURS: 1,
  IGNORE_UNTIL_MIDNIGHT: 2,
  IGNORE_INDEFINITELY: 3,
  ACCEPT_AS_NORMAL: 4,
  OPEN_VALVE_DD: 5,
  IGNORE_24_HOURS: 6,
  CLOSE_VALVE_DD: 7,
  CLOSE_VALVE_NVS: 8,
  CLOSE_VALVE_CPS: 9,
  CLOSE_VALVE_MANUAL: 10,
  OPEN_VALVE_NVS: 11,
  OPEN_VALVE_CPS: 12,
  OPEN_VALVE_MANUAL: 13,
  OPEN_VALVE_WEB: 14,
  CLOSE_VALVE_WEB: 15,
  IGNORE_7_DAYS: 16,
  CLOSE_VALVE_FROM_PHONE_CALL: 17,
  IGNORE_30_DAYS: 18
};

export const handleICDAlarmIncidentRegistry = async (icdAlarmIncidentRegistryOldAndNew: any): Promise<void> => {
  const old = icdAlarmIncidentRegistryOldAndNew.old;
  const latest = icdAlarmIncidentRegistryOldAndNew.new;
  const alarmId = latest.alarm_id;
  const deviceId = latest.icd_data.id;
  const action = {
    deviceId: deviceId,
    alarmIds: [alarmId],
    snoozeSeconds: 0
  };

  console.log(`Migrating user actions for device: ${deviceId} and alarm: ${alarmId}.`);

  if(old.user_action_taken == null && latest.user_action_taken != null) {
    return gatewayService.sendUserAction({
      ...action,
      snoozeSeconds: getSnoozeSecondsFromActionId(latest.user_action_taken.action_id, latest.icd_data.timezone)
    });
  }

  if(old.acknowledged_by_user == 0 && latest.acknowledged_by_user == 1) {
    return gatewayService.sendUserAction(action);
  }

  return Promise.resolve();
};

function getSnoozeSecondsFromActionId(actionId: number, timezoneId: string) {
  const now = moment().tz(timezoneId);

  switch (actionId) {
    case USER_ACTION.IGNORE_2_HOURS:
      return 7200;

    case USER_ACTION.IGNORE_7_DAYS:
      return 604800;

    case USER_ACTION.IGNORE_30_DAYS:
      return 2592000;

    case USER_ACTION.IGNORE_UNTIL_MIDNIGHT:
      const midnight = now.endOf('day');
      const duration = moment.duration(midnight.diff(now));

      return duration.asSeconds();

    case USER_ACTION.IGNORE_INDEFINITELY:
      return 31556952;

    case USER_ACTION.IGNORE_24_HOURS:
      return 86400;

    default:
      return 0;
  }
}

