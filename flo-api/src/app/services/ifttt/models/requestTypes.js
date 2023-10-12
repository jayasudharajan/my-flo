import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TSystemMode from './TSystemMode';

const TAlertTriggerBody = t.struct({
  trigger_identity: t.String,
  triggerFields: t.struct({
    alert_ids: t.String
  }),
  limit: t.maybe(t.Number),
  user: t.Any,
  ifttt_source: t.maybe(t.Any)
});

const TBaseActionBody = t.struct({
  user: t.Any,
  ifttt_source: t.maybe(t.Any)
});

const TChangeSystemModeActionBody = t.struct.extend([
  TBaseActionBody,
  t.struct({
    actionFields: t.struct({
      device_mode: TSystemMode
    })
  })
]);

export default {
  getStatus: {},
  testSetup: {},
  getUserInfo: {},
  deleteTriggerIdentity: {
    params: {
      trigger_slug: t.String,
      trigger_identity: t.String
    }
  },
  getCriticalAlertDetectedTriggerEvents: {
    body: TAlertTriggerBody
  },
  getWarningAlertDetectedTriggerEvents: {
    body: TAlertTriggerBody
  },
  getInfoAlertDetectedTriggerEvents: {
    body: TAlertTriggerBody
  },
  openValveAction: {
    body: TBaseActionBody
  },
  closeValveAction: {
    body: TBaseActionBody
  },
  changeSystemModeAction: {
    body: TChangeSystemModeActionBody
  },
  notifyRealtimeAlert: {
    body: t.struct({
      icd_id: tcustom.UUIDv4,
      severity: t.Integer
    })
  }
}