import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAccountGroupAlarmNotificationDeliveryRule = t.struct({
  group_id: tcustom.UUIDv4,
  user_role: t.String,
  alarm_id: t.Integer,
  system_mode: t.Integer,
  internal_id: t.Integer,
  severity: t.Integer,
  mandatory: t.list(t.Integer),
  optional: t.list(t.Integer),
  filter_settings: t.struct({
    exempted: t.Boolean,
    max_delivery_amount: t.Integer,
    max_delivery_amount_scope: t.Integer,
    max_minutes_elapsed_since_incident_time: t.Integer,
    send_when_valve_is_closed: t.Boolean
  }),
  graveyard_time: t.struct({
    enabled: t.Boolean,
    ends_time_in_24_format: t.String,
    send_app_notification: t.Boolean,
    send_email: t.Boolean,
    send_sms: t.Boolean,
    start_time_in_24_format: t.String
  })
});

TAccountGroupAlarmNotificationDeliveryRule.create = data => TAccountGroupAlarmNotificationDeliveryRule(data);

export default TAccountGroupAlarmNotificationDeliveryRule;