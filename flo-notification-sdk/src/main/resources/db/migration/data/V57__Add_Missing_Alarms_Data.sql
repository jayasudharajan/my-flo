-- alarm
INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
VALUES(12, 'hot_water', 2, false, true, true, '1 hours', NULL, '{}', true) ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
VALUES(44, 'mode_change', 3, true, true, true, '1 hours', NULL, '{}', false) ON CONFLICT DO NOTHING;


-- alarm_system_mode_settings
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(168, 12, 2, false, true, false, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(169, 12, 3, false, true, false, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(170, 12, 5, false, true, false, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(171, 44, 2, NULL, NULL, NULL, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(172, 44, 3, NULL, NULL, NULL, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(173, 44, 5, NULL, NULL, NULL, NULL);
