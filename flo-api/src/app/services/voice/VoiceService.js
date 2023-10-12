 import DIFactory from  '../../../util/DIFactory';
import VoiceServiceConfig from './VoiceServiceConfig';
import ClientType from '../../../util/ClientType';
import ICDAlarmIncidentRegistryTable from '../../models/ICDAlarmIncidentRegistryTable';
import ICDAlarmIncidentRegistryLogTable from '../../models/ICDAlarmIncidentRegistryLogTable';
import TwilioVoiceRequestLogTable from './TwilioVoiceRequestLogTable';
import NotFoundException from '../utils/exceptions/NotFoundException';
import { USER_ACTION, updateAlarmWithUserAction, SYSTEM_MODES } from '../../../util/alarmUtils';
import DeliveryMediumLogStatus from './models/DeliveryMediumLogStatus';
import DeliveryMediums from './models/DeliveryMediums';
import { lookupByICDId } from '../../../util/icdUtils';
import directives from '../../../util/directives';
import SystemMode from './models/SystemMode';
import uuid from 'node-uuid';
import _ from 'lodash';
const VoiceResponse = require('twilio').twiml.VoiceResponse;

class VoiceService {

	constructor(voiceServiceConfig, icdAlarmIncidentRegistryTable, icdAlarmIncidentRegistryLogTable, twilioVoiceRequestLogTable) {
	  this.config = voiceServiceConfig;
	  this.icdAlarmIncidentRegistryTable = icdAlarmIncidentRegistryTable;
    this.icdAlarmIncidentRegistryLogTable = icdAlarmIncidentRegistryLogTable;
    this.twilioVoiceRequestLogTable = twilioVoiceRequestLogTable;
	}

  gatherUserAction(userId, incidentId, receiptId, digits, gatherUrl, rawData, log) {

    return Promise.all([
      this.icdAlarmIncidentRegistryTable.retrieve({ id: incidentId }),
      this.twilioVoiceRequestLogTable.createLatest({
        incident_id: incidentId,
        user_id: userId,
        ...rawData
      })
    ])
    .then(([ queryResult ]) => {

      if(_.isEmpty(queryResult)) {
        throw new NotFoundException("Incident not found.");
      }

      const alarmIncidentRegistry = queryResult.Item;
      const icdId = alarmIncidentRegistry.icd_id;
      const systemMode = alarmIncidentRegistry.icd_data.system_mode;
      const appUsed = ClientType.PHONE_CALL;

      const getAlarmWithUserActionData = (actionId) => ({
        incident_id: incidentId,
        action_id: actionId,
        icd_id: icdId,
        alarm_id: alarmIncidentRegistry.alarm_id,
        system_mode: systemMode,
        user_id: userId,
        timezone: alarmIncidentRegistry.icd_data.timezone,
        app_used: appUsed,
        action_executor: this._mapToActionExecutor(actionId, icdId, userId, appUsed, log),
        should_not_be_acknowledged: true
      });

      const userSelection = this._mapDigits(systemMode, digits, gatherUrl);

      return Promise.all([
        Promise.resolve(userSelection.twiml.toString()),
        this._handleUserAction(userSelection.userAction, getAlarmWithUserActionData(userSelection.userAction)),
        this._saveIcdAlarmIncidentRegistryLog(incidentId, userId, receiptId)
      ])
    })
    .then(([ result ]) => result);
  }

  _mapToActionExecutor(actionId, icdId, userId, appUsed, log) {
    if(actionId == USER_ACTION.CLOSE_VALVE_FROM_PHONE_CALL) {
      return () => this._closeValve(icdId, userId, appUsed, log)
    }

    if(actionId == USER_ACTION.SLEEP_2_HOURS) {
      return () => this._setToSleepMoveFor2Hours(icdId, userId, appUsed, log)
    }
  }

	_handleUserAction(userAction, alarmWithUserActionData) {
    return !userAction ?
      Promise.resolve() :
      updateAlarmWithUserAction(alarmWithUserActionData);
  }

  _saveIcdAlarmIncidentRegistryLog(incidentId, userId, receiptId) {
    return this.icdAlarmIncidentRegistryLogTable.create({
      id: uuid.v4(),
      icd_alarm_incident_registry_id: incidentId,
      user_id: userId,
      delivery_medium: DeliveryMediums.VOICE,
      status: DeliveryMediumLogStatus.OPENED,
      receipt_id: receiptId
    });
  };

  _setToSleepMoveFor2Hours(icd_id, user_id, app_used, log) {
    const systemmodeid = SYSTEM_MODES.SLEEP;
    const sleep_minutes = 120;

    return lookupByICDId(icd_id, log)
        .then(({ device_id, id: icd_id }) =>
            directives(user_id, app_used, log).sleep({ icd_id, device_id, systemmodeid, sleep_minutes })
        )
  }

  _closeValve(icd_id, user_id, app_used, log) {
    return lookupByICDId(icd_id, log)
      .then(({ device_id, id: icd_id }) =>
        directives(user_id, app_used, log).toggleValve({ icd_id, device_id, valveaction: 'close' })
      )
  }

  _mapDigits(systemMode, digits, gatherUrl) {
    // Use the Twilio Node.js SDK to build an XML response
    const twiml = new VoiceResponse();

    switch (digits) {
      case '0':
        twiml.play(this.config.getVoiceCallOption0Audio());
        twiml.dial(this.config.getCustomerCarePhone());
        return { twiml, userAction: null };
      case '1':
        if(systemMode == SystemMode.HOME) {
          twiml.play(this.config.getVoiceCallOption1Audio());
          twiml.hangup();
          return { twiml, userAction: USER_ACTION.CLOSE_VALVE_FROM_PHONE_CALL };
        }
      case '2':
        if(systemMode == SystemMode.HOME) {
          twiml.play(this.config.getVoiceCallOption2Audio());
          twiml.hangup();

          return {twiml, userAction: USER_ACTION.SLEEP_2_HOURS};
        }
      default:
        if(systemMode == SystemMode.HOME) {
          twiml.redirect(this.config.getVoiceCallHomeWrongInputUrl(gatherUrl));
        } else {
          twiml.redirect(this.config.getVoiceCallAwayWrongInputUrl(gatherUrl));
        }
        return { twiml, userAction: null };
    }
  }
}

export default new DIFactory(
  VoiceService,
  [ VoiceServiceConfig, ICDAlarmIncidentRegistryTable, ICDAlarmIncidentRegistryLogTable, TwilioVoiceRequestLogTable ]
);
