-- alarm
INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(3, 'health_test_skipped', 3, true, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(39, 'health_test_canceled', 3, false, true, true, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(48, 'valve_close', 3, false, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(55, 'water_use_in_away_mode', 1, false, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(56, 'health_test_skipped', 3, false, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(57, 'water_pressure_over_recommended_max', 2, false, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(58, 'device_rebooted', 3, true, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(59, 'zit_interrupted', 3, true, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(60, 'zit_skipped', 3, true, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(61, 'zit_interrupted', 3, true, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(62, 'zit_interrupted', 3, true, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(5004, 'frequent_low_flow_event', 2, true, true, false, false, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

-- delivery_medium_template
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(118, 3, 2, NULL, 'nr.alarm.3.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(119, 3, 3, 'nr.alarm.3.subject', 'nr.alarm.3.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(120, 3, 4, NULL, 'nr.alarm.3.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(121, 39, 2, NULL, 'nr.alarm.39.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(122, 39, 3, 'nr.alarm.39.subject', 'nr.alarm.39.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(123, 39, 4, NULL, 'nr.alarm.39.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(124, 48, 2, NULL, 'nr.alarm.48.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(125, 48, 3, 'nr.alarm.48.subject', 'nr.alarm.48.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(126, 48, 4, NULL, 'nr.alarm.48.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(127, 55, 2, NULL, 'nr.alarm.55.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(128, 55, 3, 'nr.alarm.55.subject', 'nr.alarm.55.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(129, 55, 4, NULL, 'nr.alarm.55.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(130, 56, 2, NULL, 'nr.alarm.56.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(131, 56, 3, 'nr.alarm.56.subject', 'nr.alarm.56.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(132, 56, 4, NULL, 'nr.alarm.56.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(133, 57, 2, NULL, 'nr.alarm.57.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(134, 57, 3, 'nr.alarm.57.subject', 'nr.alarm.57.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(135, 57, 4, NULL, 'nr.alarm.57.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(136, 58, 2, NULL, 'nr.alarm.58.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(137, 58, 3, 'nr.alarm.58.subject', 'nr.alarm.58.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(138, 58, 4, NULL, 'nr.alarm.58.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(139, 59, 2, NULL, 'nr.alarm.59.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(140, 59, 3, 'nr.alarm.59.subject', 'nr.alarm.59.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(141, 59, 4, NULL, 'nr.alarm.59.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(142, 60, 2, NULL, 'nr.alarm.60.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(143, 60, 3, 'nr.alarm.60.subject', 'nr.alarm.60.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(144, 60, 4, NULL, 'nr.alarm.60.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(145, 61, 2, NULL, 'nr.alarm.61.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(146, 61, 3, 'nr.alarm.61.subject', 'nr.alarm.61.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(147, 61, 4, NULL, 'nr.alarm.61.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(148, 62, 2, NULL, 'nr.alarm.62.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(149, 62, 3, 'nr.alarm.62.subject', 'nr.alarm.62.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(150, 62, 4, NULL, 'nr.alarm.62.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(151, 5004, 2, NULL, 'nr.alarm.5004.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(152, 5004, 3, 'nr.alarm.5004.subject', 'nr.alarm.5004.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(153, 5004, 4, NULL, 'nr.alarm.5004.template');

-- alarm_system_mode_settings
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(102, 3, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(103, 3, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(104, 3, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(105, 39, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(106, 39, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(107, 39, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(108, 48, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(109, 48, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(110, 48, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(111, 55, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(112, 55, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(113, 55, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(114, 56, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(115, 56, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(116, 56, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(117, 57, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(118, 57, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(119, 57, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(120, 58, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(121, 58, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(122, 58, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(123, 59, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(124, 59, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(125, 59, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(126, 60, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(127, 60, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(128, 60, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(129, 61, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(130, 61, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(131, 61, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(132, 62, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(133, 62, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(134, 62, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(135, 5004, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(136, 5004, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(137, 5004, 5, false, true, true, NULL);