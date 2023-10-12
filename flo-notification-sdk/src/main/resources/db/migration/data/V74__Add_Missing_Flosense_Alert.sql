-- alarm
INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
VALUES(74, 'unusual_usage', 1, false, false, true, '1 hours', NULL, '{}', false);

-- alarm_system_mode_settings
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(190, 74, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(191, 74, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(192, 74, 5, false, true, true, NULL);