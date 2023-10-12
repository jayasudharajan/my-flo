import _ from 'lodash';
import config from "../../../config/config";
import uuid from 'uuid';
import DIFactory from  '../../../util/DIFactory';
import { IFTTTService } from './IFTTTService';
import TriggerIdentityTable from './TriggerIdentityLogTable';
import OAuth2Service from '../oauth2/OAuth2Service';
import TUserInfoResponse from './models/TUserInfoResponse';
import TAlertDetectedTriggerResponse from './models/TAlertDetectedTriggerResponse';
import { ALARM_SEVERITY } from '../../../util/alarmUtils';
import TSystemMode from './models/TSystemMode';

class IFTTTTestService extends IFTTTService {
  constructor(triggerIdentityTable, oauth2Service) {
    super(triggerIdentityTable);

    this.oauth2Service = oauth2Service;
    this.user = {
      id: uuid.v4(),
      name: 'Test user'
    };
  }

  _generateAlertEvents(severity, alertIds, limit) {
    var timestamp = 1534977758;

    const alertsData = _.range(5).map(x => {
      return (alertIds || this._getAllAlertsIdsBySeverity(severity)).map(alertId => {
        const eventId = `${alertId}-${this.user.id}-${x}`;

        timestamp = timestamp + 120;

        return {
          alert_id: eventId,
          alert_name: `name-${this.user.id}`,
          system_mode: `${_.capitalize(TSystemMode.getNameByKey(3))} Mode`,
          full_address: '3760 S Robertson Blvd, Culver City, CA 90232',
          created_at: '2016-09-18T17:34:02.666Z',
          incident_time: timestamp,
          meta: {
            id: eventId,
            timestamp: timestamp
          }
        };
      });
    });

    const result = _.orderBy(_.flatten(alertsData), ['incident_time'], ['desc']).slice(0, limit);

    return TAlertDetectedTriggerResponse.create({ data: result })
  }

  _getAllAlertsIdsBySeverity(severity) {
    switch (severity) {
      case ALARM_SEVERITY.HIGH:
        return [10, 11, 26, 52, 53];
      case ALARM_SEVERITY.MEDIUM:
        return [13, 14, 15, 16, 18, 22, 23, 28, 29, 30, 31, 33];
      case ALARM_SEVERITY.LOW:
        return [5, 34, 32, 39, 40, 41, 45, 50];
      default:
        return [];
    }
  }

  issueTestAccessToken() {
    const client = {
      client_id: config.iftttClientId
    };
    const ttl = 86400;

    return this.oauth2Service.retrieveAuthorizationDetails(client.client_id)
      .then(({ scopes }) => this.oauth2Service.loadClientScopeRoles(
          client.client_id, this.user.id, scopes.map(scope => scope.scope_name)
        )
      )
      .then(() => this.oauth2Service.createAccessToken(client, this.user, ttl, { is_ifttt_test: true }))
      .then(({ token }) => token);
  }

  testSetup() {
    return this
      .issueTestAccessToken()
      .then(accessToken => {
        return {
          data: {
            accessToken,
            samples: {
              triggers: {
                critical_alert_detected: {
                  alert_ids: '10,11,26,52,53'
                },
                warning_alert_detected: {
                  alert_ids: '13,14,15,16,18,22,23,28,29,30,31,33'
                },
                info_alert_detected: {
                  alert_ids: '5,34,32,39,40,41,45,50'
                }
              },
              actions: {
                turn_water_on: {},
                turn_water_off: {},
                change_device_mode: {
                  device_mode: '2'
                }
              }
            }
          }
        };
      });
  }

  getUserInfo(userId) {
    return Promise.resolve(
      TUserInfoResponse.create({
        data: this.user
      })
    );
  }

  deleteTriggerIdentity(userId, triggerIdentity) {
    return Promise.resolve();
  }

  getAlertDetectedTriggerEventsBySeverity(userId, severity, floTriggerId, triggerData) {
    //If they send limit 0, doing triggerData.limit || 50 will return 50
    const limit = (triggerData.limit || triggerData.limit == 0) ? triggerData.limit : 50;
    const alertIds = triggerData.triggerFields.alert_ids;
    const alertsFilter = alertIds && alertIds.split(',').filter(alarmId => alarmId).map(alarmId => parseInt(alarmId.trim()));

    return Promise.resolve(this._generateAlertEvents(severity, alertsFilter, limit));
  }

  openValveAction(userId) {
    return Promise.resolve({
      data: [{
        id: uuid.v4()
      }]
    });
  }

  closeValveAction(userId) {
    return Promise.resolve({
      data: [{
        id: uuid.v4()
      }]
    });
  }

  changeSystemModeAction(userId, actionData) {
    return Promise.resolve({
      data: [{
        id: new Date().getTime()
      }]
    });
  }
}

export default DIFactory(
  IFTTTTestService,
  [TriggerIdentityTable, OAuth2Service]
);