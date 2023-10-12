import DIFactory from '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';
import TriggerId from './models/TriggerId';
import { ALARM_SEVERITY } from '../../../util/alarmUtils';

class IFTTTController {
  constructor(iftttServiceFactory) {
    this.iftttServiceFactory = iftttServiceFactory;
  }

  getStatus() {
    return this.iftttServiceFactory().getStatus();
  }

  getUserInfo({ token_metadata: { user_id, is_ifttt_test } }) {
    return this.iftttServiceFactory(is_ifttt_test).getUserInfo(user_id);
  }

  testSetup() {
    return this.iftttServiceFactory(true).testSetup();
  }

  deleteTriggerIdentity({ token_metadata: { is_ifttt_test }, params: { trigger_slug, trigger_identity } }) {
    return this.iftttServiceFactory(is_ifttt_test).deleteTriggerIdentity(trigger_slug, trigger_identity);
  }

  getCriticalAlertDetectedTriggerEvents({ token_metadata: { user_id, is_ifttt_test }, body: triggerData }) {
    return this.iftttServiceFactory(is_ifttt_test)
      .getAlertDetectedTriggerEventsBySeverity(
        user_id, ALARM_SEVERITY.HIGH, parseInt(TriggerId.CRITICAL_ALERT_DETECTED), triggerData
      );
  }

  getWarningAlertDetectedTriggerEvents({ token_metadata: { user_id, is_ifttt_test }, body: triggerData }) {
    return this.iftttServiceFactory(is_ifttt_test)
      .getAlertDetectedTriggerEventsBySeverity(
        user_id, ALARM_SEVERITY.MEDIUM, parseInt(TriggerId.WARNING_ALERT_DETECTED), triggerData
      );
  }

  getInfoAlertDetectedTriggerEvents({ token_metadata: { user_id, is_ifttt_test }, body: triggerData }) {
    return this.iftttServiceFactory(is_ifttt_test)
      .getAlertDetectedTriggerEventsBySeverity(
        user_id, ALARM_SEVERITY.LOW, parseInt(TriggerId.INFO_ALERT_DETECTED), triggerData
      );
  }

  openValveAction({ token_metadata: { user_id, is_ifttt_test } }) {
    return this.iftttServiceFactory(is_ifttt_test).openValveAction(user_id);
  }

  closeValveAction({ token_metadata: { user_id, is_ifttt_test } }) {
    return this.iftttServiceFactory(is_ifttt_test).closeValveAction(user_id);
  }

  changeSystemModeAction({ token_metadata: { user_id, is_ifttt_test }, body: actionData }) {
    return this.iftttServiceFactory(is_ifttt_test).changeSystemModeAction(user_id, actionData);
  }

  notifyRealtimeAlert({ body: { icd_id, severity } }) {
    return this.iftttServiceFactory(false).notifyRealtimeAlert(icd_id, severity);
  }
}

export default new DIFactory(new ControllerWrapper(IFTTTController), ['IFTTTServiceFactoryFactory']);