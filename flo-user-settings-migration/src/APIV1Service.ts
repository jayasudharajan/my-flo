import axios from 'axios';
import _ from 'lodash';
import SystemMode from './constants/SystemMode';
import DripAlarms from './constants/DripAlarms';
import config from './config';

const apiBaseURI = `${config.apiV1Url}/api/v1`;

const userAlarmNotificationDeliveryRulesURI = `${apiBaseURI}/useralarmnotificationdeliveryrules`;
const userLocationAlarmNotificationDeliveryRulesURI = `${userAlarmNotificationDeliveryRulesURI}/userlocation`;

const icdAlarmNotificationDeliveryRulesURI = `${apiBaseURI}/icdalarmnotificationdeliveryrules`;
const icdAlarmNotificationDeliveryRulesScanURI = `${icdAlarmNotificationDeliveryRulesURI}/scan`;

export default class APIV1Service {
  fetchPreferences(userId: string, locationId: string) {
    return Promise.all( [
      axios.get( icdAlarmNotificationDeliveryRulesScanURI ),
      axios.get( `${userLocationAlarmNotificationDeliveryRulesURI}/${userId}/${locationId}`, { validateStatus: status => ( status >= 200 && status < 300 ) || ( status >= 400 && status < 500 ) } )
    ])
      .then( results => {
        const { data: { Items: icdRules } } = results[ 0 ];
        const { data: userRules } = results[ 1 ];
        return [ icdRules, userRules ];
      });
  }

  getCombinedPreferences(userId: string, locationId: string) {
    const preferences = this.fetchPreferences(userId, locationId);

    return preferences
      .then(([icdAlarmPreferences, userAlarmPreferences]) => {
        const icdNewPreferences = icdAlarmPreferences.map((icdAlarmPreference: any) => {
          const match = _.find(userAlarmPreferences, userAlarmPreference => {
            return icdAlarmPreference.alarm_id == userAlarmPreference.alarm_id &&
              icdAlarmPreference.system_mode == userAlarmPreference.system_mode;
          });

          if(match) {
            return {
              ...icdAlarmPreference,
              ...match,
            }
          }
          return icdAlarmPreference;
        });

        return _.uniqWith(_.concat(icdNewPreferences, userAlarmPreferences), (x, y) => {
          return x.alarm_id == y.alarm_id && x.system_mode == y.system_mode;
        });
      });
  }

  _getSmallDripPreferences(combinedPreferences: any) {
    const smallDripPreferences = combinedPreferences
      .filter((x: any) => {
        return x.is_deleted == false && x.is_user_overwritable == true && DripAlarms.isDripAlarm(x.alarm_id)
      });

    return _.sortBy(smallDripPreferences, ['alarm_id']);
  }

  getLeakSensitivity(combinedPreferences: any) {
      const filteredPreferences = this._getSmallDripPreferences(combinedPreferences)
        .filter((x: any) =>
          x.system_mode == SystemMode.HOME.id && x.alarm_id
        )
        .map((x: any) => {
          return { ...x, is_muted: x.is_muted || false };
        });

      let dripAlarmSensitivity = 0;

      _.sortBy(filteredPreferences, ['alarm_id']).forEach(x => {
        if(!x.is_muted) {
          dripAlarmSensitivity += 1;
        }
      });

      return dripAlarmSensitivity;
  }

  _fromIcdAlarmPreferencesToUserPreferences(preferences: any) {
    let result = {
      ...preferences,
    };

    delete result.icd_action;
    delete result.has_action;
    delete result.message_templates;
    delete result.user_actions;
    delete result.is_user_overwritable;
    delete result.is_deleted;
    delete result.action;

    return result;
  }
}
