import _ from 'lodash';
import moment from 'moment-timezone';
import uuid from 'node-uuid';
import ICDAlarmIncidentRegistryTable from '../app/models/ICDAlarmIncidentRegistryTable';
import AlarmNotificationDeliveryFilterTable from '../app/models/AlarmNotificationDeliveryFilterTable';
import { publish } from './mqttUtils';
import { lookupByICDId } from './icdUtils';
import { errorTypes } from '../config/constants';

const ICDAlarmIncidentRegistry = new ICDAlarmIncidentRegistryTable();
const AlarmNotificationDeliveryFilter = new AlarmNotificationDeliveryFilterTable();

export const ALARM_SEVERITY = {
  HIGH: 1,
  MEDIUM: 2,
  LOW: 3
};

export const USER_ACTION = {
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
  IGNORE_30_DAYS: 18,
  SLEEP_2_HOURS: 100
};

const FILTER_STATUS = {
  RESOLVED: 1,
  IGNORED: 2,
  UNRESOLVED: 3
};

const NOTIFICATIONS_RESPONSE_ACTION = {
  NONE: -1,
  ACCEPT_AS_NORMAL: 0,
  SNOOZE: 1,
  CLOSE_VALVE: 2,
  OPEN_VALVE: 3,
  SWITCH_TO_HOME_MODE: 4
};

const NOTIFICATIONS_RESPONSE_DELAY = {
  // Specific delay is Unix timestamp in seconds of the UTC time when action should occur
  PERMANENT: -1,
  IMMEDIATE: 0
};

export const USER_ACKNOWLEDGEMENT = {
  UNACKNOWLEDGED: 0,
  ACKNOWLEDGED: 1
};

export const ALARM_IDS = {
  ZIT_SUCCESSFUL: 5,
  FLOOR_MOISTURE: 9,
  FAST_WATER_FLOW: 10,
  MAX_FLOW: 11,
  DAILY_USAGE: 12,
  MIN_TEMPERATURE: 13,
  CLOUD_COMMUNICATION_ERROR: 13,
  MAX_TEMPERATURE: 14,
  MIN_PRESSURE: 15,
  MAX_PRESSURE: 16,
  VALVE_TIMEOUT: 18,
  FLOOR_MOISTURE_SENSOR_ERROR: 20,
  PROXIMITY_SENSOR_ERROR: 21,
  GENERAL_ERROR: 22,
  DEVICE_MEMORY_ERROR: 23,
  PRESSURE_SENSOR_ERROR: 24,
  TEMPERATURE_SENSOR_ERROR: 25,
  FLOW_DURATION: 26,
  ZIT_LEAK_CAT_1: 28,
  ZIT_LEAK_CAT_2: 29,
  ZIT_LEAK_CAT_3: 30,
  ZIT_LEAK_CAT_4: 31,
  ZIT_INTERRUPTED: 32,
  MANUAL_ZIT_SUCESSFUL: 34 ,
  WATER_SYSTEM_SHUTOFF_DUE_FAST_WATER_FLOW: 51,
  WATER_SYSTEM_SHUTOFF_DUE_HIGH_WATER_USAGE: 52,
  WATER_SYSTEM_SHUTOFF_DUE_EXTENDED_WATER_USE: 53
};

export const SYSTEM_MODES = {
  HOME: 2,
  AWAY: 3,
  VACATION: 4,
  SLEEP: 5
};

const FLOW_RELATED_ALARM_ID_SYSTEM_MODES = [
  '10_2',
  '10_3',
  '10_4',
  '26_2',
  '26_3',
  '26_4',
  '11_2',
  '11_3',
  '11_4',
  '28_2',
  '28_3',
  '28_4',
  '29_2',
  '29_3',
  '29_4',
  '13_2',
  '13_3',
  '13_4',
  '14_2',
  '14_3',
  '14_4',
  '15_2',
  '15_3',
  '15_4',
  '16_2',
  '16_3',
  '16_4',
  '30_2',
  '30_3',
  '30_4',
  '31_2',
  '31_3',
  '31_4'
];

export function mapActionToFilterStatus(action_id) {
  switch (action_id) {

    case USER_ACTION.IGNORE_2_HOURS:
    case USER_ACTION.IGNORE_UNTIL_MIDNIGHT:
    case USER_ACTION.IGNORE_24_HOURS:
    case USER_ACTION.IGNORE_INDEFINITELY:
    case USER_ACTION.IGNORE_7_DAYS:
    case USER_ACTION.IGNORE_30_DAYS:
      return FILTER_STATUS.IGNORED;

    case USER_ACTION.ACCEPT_AS_NORMAL:
    case USER_ACTION.OPEN_VALVE_DD:
    case USER_ACTION.OPEN_VALVE_NVS:
    case USER_ACTION.OPEN_VALVE_CPS:
    case USER_ACTION.OPEN_VALVE_MANUAL:
    case USER_ACTION.OPEN_VALVE_WEB:
    case USER_ACTION.CLOSE_VALVE_DD:
    case USER_ACTION.CLOSE_VALVE_NVS:
    case USER_ACTION.CLOSE_VALVE_CPS:
    case USER_ACTION.CLOSE_VALVE_WEB:
    case USER_ACTION.CLOSE_VALVE_MANUAL:
      return FILTER_STATUS.RESOLVED;

    default:
      return FILTER_STATUS.UNRESOLVED;
  }
}


function mapActionToExpiration(user_action, date, timezoneId) {
  const momentJsDate = moment(date);

  switch (user_action) {

    case USER_ACTION.IGNORE_2_HOURS:
      return momentJsDate.add(2, 'hours');

    case USER_ACTION.IGNORE_7_DAYS:
      return momentJsDate.add(7, 'days');

    case USER_ACTION.IGNORE_30_DAYS:
      return momentJsDate.add(30, 'days');

    case USER_ACTION.IGNORE_UNTIL_MIDNIGHT:
      return momentJsDate.tz(timezoneId).endOf('day').tz('Etc/UTC');

    case USER_ACTION.IGNORE_INDEFINITELY:
      return momentJsDate.add(100, 'years'); // 100 years in place of "forever"

    case USER_ACTION.IGNORE_24_HOURS:
      return momentJsDate.add(24, 'hours');

    default:
      return momentJsDate;
  }
}

function mapActionToNotificationResponse(user_action, date, timezoneId) {
  const delay = mapActionToExpiration(user_action, date, timezoneId).valueOf();

  switch (user_action) {

    case USER_ACTION.IGNORE_2_HOURS:
    case USER_ACTION.IGNORE_7_DAYS:
    case USER_ACTION.IGNORE_UNTIL_MIDNIGHT:
    case USER_ACTION.IGNORE_30_DAYS:
      return [
        {
          action_id: NOTIFICATIONS_RESPONSE_ACTION.SNOOZE,
          ts: delay
        }
      ];

    case USER_ACTION.IGNORE_INDEFINITELY:
      return [
        {
          action_id: NOTIFICATIONS_RESPONSE_ACTION.SNOOZE,
          ts: NOTIFICATIONS_RESPONSE_DELAY.PERMANENT
        }
      ];

    case USER_ACTION.ACCEPT_AS_NORMAL:
      return [
        {
          action_id: NOTIFICATIONS_RESPONSE_ACTION.ACCEPT_AS_NORMAL,
          ts: NOTIFICATIONS_RESPONSE_DELAY.IMMEDIATE
        }
      ];

    case USER_ACTION.IGNORE_24_HOURS:
      return [
        {
          action_id: NOTIFICATIONS_RESPONSE_ACTION.SNOOZE,
          ts: delay
        }
      ];

    case USER_ACTION.OPEN_VALVE_DD:
    case USER_ACTION.OPEN_VALVE_CPS:
    case USER_ACTION.OPEN_VALVE_NVS:
    case USER_ACTION.OPEN_VALVE_WEB:
      return [
        {
          action_id: NOTIFICATIONS_RESPONSE_ACTION.OPEN_VALVE,
          ts: NOTIFICATIONS_RESPONSE_DELAY.IMMEDIATE
        }
      ];

    case USER_ACTION.CLOSE_VALVE_DD:
    case USER_ACTION.CLOSE_VALVE_CPS:
    case USER_ACTION.CLOSE_VALVE_NVS:
    case USER_ACTION.CLOSE_VALVE_WEB:
    case USER_ACTION.CLOSE_VALVE_FROM_PHONE_CALL:
      return [
        {
          action_id: NOTIFICATIONS_RESPONSE_ACTION.CLOSE_VALVE,
          ts: NOTIFICATIONS_RESPONSE_DELAY.IMMEDIATE
        }
      ];

    case USER_ACTION.OPEN_VALVE_MANUAL:
    case USER_ACTION.CLOSE_VALVE_MANUAL:
    default:
      return []; // Unresolved
  }
}

function updateAlarmNotificationDeliveryFilter({ user_id, icd_id, alarm_id, system_mode, action_id, timezone, now }) {
  const alarm_id_system_mode = alarm_id + '_' + system_mode;
  const status = mapActionToFilterStatus(action_id);
  const expires_at = mapActionToExpiration(action_id, now, timezone).toISOString();

  return AlarmNotificationDeliveryFilter.retrieve({ icd_id, alarm_id_system_mode })
    .then(({ Item }) => {

      if (!Item) {
        return Promise.reject(errorTypes.ALARM_DELIVERY_FILTER_NOT_FOUND)
      }

      return AlarmNotificationDeliveryFilter.patch({ icd_id, alarm_id_system_mode }, {
        last_decision_user_id: user_id,
        updated_at: now.toISOString(),
        status,
        expires_at
      });
    });
}

function getAssociatedAlarmIds(alarm_id) {
  switch (alarm_id) {
    case ALARM_IDS.WATER_SYSTEM_SHUTOFF_DUE_FAST_WATER_FLOW:
      return [ALARM_IDS.FAST_WATER_FLOW];
    case ALARM_IDS.WATER_SYSTEM_SHUTOFF_DUE_HIGH_WATER_USAGE:
      return [ALARM_IDS.MAX_FLOW];
    case ALARM_IDS.WATER_SYSTEM_SHUTOFF_DUE_EXTENDED_WATER_USE:
      return [ALARM_IDS.FLOW_DURATION];
    case ALARM_IDS.ZIT_LEAK_CAT_1:
    case ALARM_IDS.ZIT_LEAK_CAT_2:
    case ALARM_IDS.ZIT_LEAK_CAT_3:
    case ALARM_IDS.ZIT_LEAK_CAT_4:
      return [
        ALARM_IDS.ZIT_LEAK_CAT_1,
        ALARM_IDS.ZIT_LEAK_CAT_2,
        ALARM_IDS.ZIT_LEAK_CAT_3,
        ALARM_IDS.ZIT_LEAK_CAT_4
      ]
      .filter(associatedAlarmId => alarm_id !== associatedAlarmId);
    default:
      return [];
  }
}

function updateICDAlarmIncidentRegistry({ user_id, action_id, incident_id, app_used, should_not_be_acknowledged }) {
  const user_action_taken = { user_id, action_id, app_used, execution_time: new Date().toISOString() };

  return ICDAlarmIncidentRegistry.retrieve({ id: incident_id })
    .then(({ Item }) => {

      if (!Item) {
        throw errorTypes.ICD_ALARM_INCIDENT_REGISTRY_NOT_FOUND;
      }

      const data = {
        user_action_taken
      };

      if(!should_not_be_acknowledged) {
        data.acknowledged_by_user = USER_ACKNOWLEDGEMENT.ACKNOWLEDGED;
      }

      return ICDAlarmIncidentRegistry.patch({ id: incident_id }, data);
    });
}

function sendNotificationsResponse({ device_id, action_id, alarm_id, system_mode, timezone, now }) {
  const mqttTopic = 'home/device/' + device_id + '/v1/notifications-response';
  const actions = mapActionToNotificationResponse(action_id, now, timezone);

  return publish(mqttTopic, JSON.stringify({
    id: uuid.v4(),
    time: now.toISOString(),
    alarm_id,
    system_mode,
    ack_topic: '',
    actions
  }));
}

export function updateAlarmWithUserAction(
  {
    incident_id,
    action_id,
    icd_id,
    alarm_id,
    system_mode,
    user_id,
    app_used,
    timezone: _timezone,
    action_executor,
    should_not_be_acknowledged
  },
  updatedAlarmIds = []
) {
  if(action_id == USER_ACTION.SLEEP_2_HOURS) {
    return action_executor();
  }

  const timezone = _timezone || 'America/Los_Angeles';
  const now = new Date();
  const associatedAlarmIds = updatedAlarmIds.indexOf(alarm_id) >= 0 ? [] : getAssociatedAlarmIds(alarm_id);

  return Promise.all([
    updateAlarmNotificationDeliveryFilter({ user_id, icd_id, alarm_id, system_mode, action_id, timezone, now }),
    updateICDAlarmIncidentRegistry({ user_id, action_id, incident_id, app_used, should_not_be_acknowledged }),
    lookupByICDId(icd_id).then(({ device_id }) => {
      return action_executor ?
        action_executor() :
        sendNotificationsResponse({ device_id, alarm_id, system_mode, action_id, timezone, now });
    }),
    Promise.all(
      associatedAlarmIds
        .map(associatedAlarmId =>
          ensureAssociatedFilter(icd_id, alarm_id, system_mode, associatedAlarmId)
            .then(associatedAlarmNotificationDeliveryFilter =>
                updateAlarmFromFilters(
                  [ associatedAlarmNotificationDeliveryFilter ],
                  { action_id, user_id, timezone, app_used },
                  [...updatedAlarmIds, ...associatedAlarmIds, alarm_id]
                )
            )
        )
    )
  ])
  .then(([result]) => result);
}

export function retrieveFlowRelatedFiltersByICDId(icd_id) {
  const promises = FLOW_RELATED_ALARM_ID_SYSTEM_MODES
    .map(alarm_id_system_mode => {
      return AlarmNotificationDeliveryFilter.retrieve({ icd_id, alarm_id_system_mode });
    });

  return Promise.all(promises)
    .then(results => results.filter(({ Item }) => Item && Item.status === FILTER_STATUS.UNRESOLVED))
    .then(results => results.map(({ Item }) => Item));
}

export function updateAlarmFromFilters(alarmFilters, { action_id, user_id, timezone, app_used }, updatedAlarmIds = []) {
  const promises = alarmFilters
    .map(({ alarm_id, system_mode, icd_id, last_icd_alarm_incident_registry_id: incident_id }) =>
      updateAlarmWithUserAction(
        {
          incident_id,
          action_id,
          icd_id,
          alarm_id,
          system_mode,
          user_id,
          timezone,
          app_used
        },
        updatedAlarmIds
      )
    );

  return Promise.all(promises);
}

export function clearNotification(user_id, icd_id, alarm_id, system_mode, clearedAlarmIds = []) {
  const alarm_id_system_mode = alarm_id + '_' + system_mode;
  const status = FILTER_STATUS.RESOLVED;
  const associatedAlarmIds = clearedAlarmIds.indexOf(alarm_id) >= 0 ? [] : getAssociatedAlarmIds(alarm_id);


  return Promise.all([
    AlarmNotificationDeliveryFilter.patchExisting(
      {
        icd_id,
        alarm_id_system_mode
      },
      {
        last_decision_user_id: user_id,
        updated_at: new Date().toISOString(),
        status: status
      },
      'ALL_NEW'
    ),
    ICDAlarmIncidentRegistry.setAcknowledgedByICDIdAlarmIdSystemMode({ icd_id, alarm_id, system_mode }),
    Promise.all(
      associatedAlarmIds
        .map(associatedAlarmId =>
          ensureAssociatedFilter(icd_id, alarm_id, system_mode, associatedAlarmId)
            .then(() => clearNotification(user_id, icd_id, associatedAlarmId, system_mode, [...clearedAlarmIds, ...associatedAlarmIds, alarm_id]))
        )
    )
  ]).then(([result1, result2]) => [result1, result2]);
}

function ensureAssociatedFilter(icd_id, alarm_id, system_mode, associatedAlarmId) {

    return AlarmNotificationDeliveryFilter.retrieve({ icd_id, alarm_id_system_mode: `${ associatedAlarmId }_${ system_mode }`})
      .then(({ Item }) =>
        Item || createAssociatedFilter(icd_id, alarm_id, system_mode, associatedAlarmId)
      );
}

function createAssociatedFilter(icd_id, alarm_id, system_mode, associatedAlarmId) {
  const alarm_id_system_mode = `${ alarm_id }_${ system_mode }`;

  return AlarmNotificationDeliveryFilter.retrieve({ icd_id, alarm_id_system_mode })
    .then(({ Item: alarmNotificationDeliveryFilter }) => {
      const now = new Date().toISOString();
      const associatedAlarmNotificationDeliveryFilter = {
        ...alarmNotificationDeliveryFilter,
        alarm_id: associatedAlarmId,
        alarm_id_system_mode: `${ associatedAlarmId }_${ system_mode }`,
        created_at: now,
        updated_at: now,
        last_decision_user_id: null,
        status: FILTER_STATUS.UNRESOLVED
      };

      return AlarmNotificationDeliveryFilter.create(associatedAlarmNotificationDeliveryFilter)
        .then(() => associatedAlarmNotificationDeliveryFilter);
    });
}
