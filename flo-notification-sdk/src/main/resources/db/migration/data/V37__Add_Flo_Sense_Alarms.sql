-- alarm
INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(70, 'unusual_flow_rate', 2, false, false, false, true, '1 hours', true, true, false, true, NULL, '{}');

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(71, 'unusual_event_duration', 2, false, false, false, true, '1 hours', true, true, false, true, NULL, '{}');

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(72, 'unusual_activity_at_this_time_of_day', 2, false, false, false, true, '1 hours', true, true, false, true, NULL, '{}');

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(73, 'unusual_activity', 2, false, false, false, true, '1 hours', true, true, false, true, NULL, '{}');

-- delivery_medium_template
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(106, 70, 2, NULL, 'nr.alarm.70.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(107, 70, 3, 'nr.alarm.70.subject', 'nr.alarm.70.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(108, 70, 4, NULL, 'nr.alarm.70.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(109, 71, 2, NULL, 'nr.alarm.71.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(110, 71, 3, 'nr.alarm.71.subject', 'nr.alarm.71.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(111, 71, 4, NULL, 'nr.alarm.71.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(112, 72, 2, NULL, 'nr.alarm.72.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(113, 72, 3, 'nr.alarm.72.subject', 'nr.alarm.72.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(114, 72, 4, NULL, 'nr.alarm.72.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(115, 73, 2, NULL, 'nr.alarm.73.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(116, 73, 3, 'nr.alarm.73.subject', 'nr.alarm.73.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(117, 73, 4, NULL, 'nr.alarm.73.template');

-- alarm_system_mode_settings
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(90, 70, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(91, 70, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(92, 70, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(93, 71, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(94, 71, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(95, 71, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(96, 72, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(97, 72, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(98, 72, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(99, 73, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(100, 73, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(101, 73, 5, false, true, true, NULL);