-- Alarm
INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(90, 'flo_sense_re_train', 3, true, true, true, '0 hours', NULL, '{}'::json, false);


--- Alarm System Mode Settings

INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(223, 90, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(224, 90, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(225, 90, 5, NULL, NULL, NULL, NULL);