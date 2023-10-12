import _ from 'lodash';
import DIFactory from  '../../../util/DIFactory';
import TUserInfoResponse from './models/TUserInfoResponse';
import TAlertDetectedTriggerResponse from './models/TAlertDetectedTriggerResponse';
import TriggerIdentityTable from './TriggerIdentityLogTable';
import InfoService from '../info/InfoService';
import AlertsService from '../alerts/AlertsService';
import DirectiveService from '../directives/DirectiveService';
import moment from 'moment-timezone';
import TSystemMode from './models/TSystemMode';
import DeviceSystemModeService from '../device-system-mode/DeviceSystemModeService';
import IFTTTActionException from './models/exceptions/IFTTTActionException';
import DeviceInForcedSleepException from '../device-system-mode/models/exceptions/DeviceInForcedSleepException';
import ClientType from '../../../util/ClientType';
import uuid from 'uuid';

export class IFTTTService {
  constructor(triggerIdentityTable, infoService, alertsService, directivesService, deviceSystemModeService, httpClient, iftttConfig) {
    this.triggerIdentityTable = triggerIdentityTable;
    this.infoService = infoService;
    this.alertsService = alertsService;
    this.directivesService = directivesService;
    this.deviceSystemModeService = deviceSystemModeService;
    this.httpClient = httpClient;
    this.iftttConfig = iftttConfig;
  }

  _getUserInfo(userId) {
    return this
      .infoService
      .users
      .retrieveByUserId(userId)
      .then(({ items: [ userInfo ] }) => userInfo);
  }

  _logTriggerIdentityIfDoesNotExists(userId, floTriggerId, { trigger_identity, trigger_slug, ifttt_source }) {
    return this
      .triggerIdentityTable
      .logTriggerIdentityIfDoesNotExists({
        trigger_identity, user_id: userId, flo_trigger_id: floTriggerId, trigger_slug, ifttt_source
      });
  }

  _getDefaultIcdId(userId) {
    return this
      ._getUserInfo(userId)
      .then(userInfo => {
        return userInfo.devices ? userInfo.devices[0].id : null;
      });
  }

  getUserInfo(userId) {
    return this
      ._getUserInfo(userId)
      .then(userInfo => {
        return TUserInfoResponse.create({
          data: {
            id: userId,
            name: `${userInfo.firstname} ${userInfo.lastname}`
          }
        });
      });
  }

  getStatus() {
    return Promise.resolve();
  }

  deleteTriggerIdentity(userId, triggerIdentity) {
    return this.triggerIdentityTable.remove({ user_id: userId, trigger_identity: triggerIdentity });
  }

  getAlertDetectedTriggerEventsBySeverity(userId, severity, floTriggerId, triggerData) {
    const alertIds = triggerData.triggerFields.alert_ids;
    //If they send limit 0, doing triggerData.limit || 50 will return 50
    const limit = (triggerData.limit || triggerData.limit == 0) ? triggerData.limit : 50;
    const alertsFilter = alertIds.split(',').filter(alarmId => alarmId).map(alarmId => parseInt(alarmId.trim()));

    return Promise.all([
      this._getUserInfo(userId),
      this._logTriggerIdentityIfDoesNotExists(userId, floTriggerId, triggerData)
    ]).then(([userInfo]) => {
      const location = userInfo.geo_locations[0];
      const addressLine = location.address2 ? `${location.address}, ${location.address2}` : `${location.address}`;
      const fullAddress = `${addressLine}, ${location.city}, ${location.state_or_province} ${location.postal_code}`;
      const icdIds = (userInfo.devices || []).map(({ id }) => id);

      return Promise
        .all(icdIds.map(icdId => {
          return this.alertsService.getFullActivityLog(
             icdId, { size: limit, page: 1, filter: _.omitBy({ severity, alarm_id: alertsFilter }, _.isEmpty) }
            );
        }))
        .then(alertsData => {
          const allAlerts = _.flatten(alertsData.map(data => data.items));
          const lastAlerts = _.orderBy(allAlerts, ['incident_time'], ['desc']).slice(0, limit);

          const result = lastAlerts.map(alert => ({
            alert_id: alert.alarm_id.toString(),
            alert_name: alert.friendly_name,
            system_mode: `${_.capitalize(TSystemMode.getNameByKey(alert.system_mode))} Mode`,
            full_address: fullAddress,
            created_at: alert.incident_time,
            meta: {
              id: alert.incident_id,
              timestamp: moment(alert.incident_time).unix()
            }
          }));

          return TAlertDetectedTriggerResponse.create({ data: result });
        });
    });
  }

  _switchValveAction(userId, toValveState) {
    return this._getDefaultIcdId(userId)
      .then(icdId => {
        return this.directivesService
          .sendDirective(
            `${toValveState}-valve`,
            icdId,
            userId,
            ClientType.OTHER,
            {}
          ).then(([notUsed, kafkaDirectiveData]) => {
            return {
              data: [{
                id: kafkaDirectiveData.directive_id
              }]
            };
          });
      });
  }

  openValveAction(userId) {
    return this._switchValveAction(userId, 'open');
  }

  closeValveAction(userId) {
    return this._switchValveAction(userId, 'close');
  }

  changeSystemModeAction(userId, actionData) {
    return this._getDefaultIcdId(userId)
      .then(icdId => {
        return this.deviceSystemModeService
          .setSystemMode(
            icdId,
            parseInt(actionData.actionFields.device_mode),
            {
              user_id: userId,
              app_used: ClientType.OTHER
            }
          );
      })
      .then(() => {
        return {
          data: [{
            id: new Date().getTime()
          }]
        };
      })
      .catch(err => {
        if (err instanceof DeviceInForcedSleepException) {
          return Promise.reject(
            new IFTTTActionException(
              'System mode cannot be changed. Please contact Flo Support for more information.'
            )
          );
        } else {
          return Promise.reject(err);
        }
      });
  }

  retrieveUsersByIcdId(icdId) {
    return this.infoService.icds.retrieveByICDId(icdId)
      .then(({ items: [icd] }) => 
        !icd ? [] : icd.users.map(({ user_id }) => user_id)
      );
  }

  notifyRealtimeAlert(icdId, alertSeverity) {
    return this.retrieveUsersByIcdId(icdId)
      .then(userIds => Promise.all(
        userIds.map(userId => 
          this.triggerIdentityTable.retrieveByUserIdFloTriggerId(userId, alertSeverity)
      )))
      .then(userTriggerIdentities => {
        const triggerIdentities = _.chain(userTriggerIdentities)
          .map(({ Items }) => Items)
          .flatten()
          .map(({ trigger_identity }) => ({
            trigger_identity
          }))
          .value();

        return triggerIdentities.length && this.httpClient({
          method: 'post',
          url: this.iftttConfig.iftttRealtimeNotificationsUrl,
          headers: {
            'IFTTT-Service-Key': this.iftttConfig.iftttServiceKey,
            'Accept': 'application/json',
            'Accept-Charset': 'utf-8',
            'Accept-Encoding': 'gzip, deflate',
            'Content-Type': 'application/json',
            'X-Request-ID': uuid.v4()
          },
          data: {
            data: triggerIdentities
          }
        });
      })
      .then(() => true);
  }
}
    

export default DIFactory(
  IFTTTService,
  [TriggerIdentityTable, InfoService, AlertsService, DirectiveService, DeviceSystemModeService, 'HttpClient', 'IFTTTConfig']
);

