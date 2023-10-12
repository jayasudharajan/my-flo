-- alarm
INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(80, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(81, 'water_system_shutoff', 1, false, true, true, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(82, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(83, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(84, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(85, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(86, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(87, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(88, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

INSERT INTO public.alarm (id, "name", severity, is_internal, send_when_valve_is_closed, exempted, enabled, max_delivery_frequency, sms_supported, email_supported, voice_supported, push_supported, parent_id, metadata)
VALUES(89, 'water_system_shutoff', 1, false, true, false, true, '1 hours', true, true, false, true, NULL, '{}') ON CONFLICT DO NOTHING;

-- delivery_medium_template
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(154, 80, 2, NULL, 'nr.alarm.80.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(155, 80, 3, 'nr.alarm.80.subject', 'nr.alarm.80.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(156, 80, 4, NULL, 'nr.alarm.80.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(157, 81, 2, NULL, 'nr.alarm.81.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(158, 81, 3, 'nr.alarm.81.subject', 'nr.alarm.81.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(159, 81, 4, NULL, 'nr.alarm.81.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(160, 82, 2, NULL, 'nr.alarm.82.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(161, 82, 3, 'nr.alarm.82.subject', 'nr.alarm.82.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(162, 82, 4, NULL, 'nr.alarm.82.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(163, 83, 2, NULL, 'nr.alarm.83.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(164, 83, 3, 'nr.alarm.83.subject', 'nr.alarm.83.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(165, 83, 4, NULL, 'nr.alarm.83.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(166, 84, 2, NULL, 'nr.alarm.84.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(167, 84, 3, 'nr.alarm.84.subject', 'nr.alarm.84.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(168, 84, 4, NULL, 'nr.alarm.84.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(169, 85, 2, NULL, 'nr.alarm.85.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(170, 85, 3, 'nr.alarm.85.subject', 'nr.alarm.85.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(171, 85, 4, NULL, 'nr.alarm.85.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(172, 86, 2, NULL, 'nr.alarm.86.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(173, 86, 3, 'nr.alarm.86.subject', 'nr.alarm.86.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(174, 86, 4, NULL, 'nr.alarm.86.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(175, 87, 2, NULL, 'nr.alarm.87.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(176, 87, 3, 'nr.alarm.87.subject', 'nr.alarm.87.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(177, 87, 4, NULL, 'nr.alarm.87.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(178, 88, 2, NULL, 'nr.alarm.88.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(179, 88, 3, 'nr.alarm.88.subject', 'nr.alarm.88.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(180, 88, 4, NULL, 'nr.alarm.88.template');

INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(181, 89, 2, NULL, 'nr.alarm.89.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(182, 89, 3, 'nr.alarm.89.subject', 'nr.alarm.89.template');
INSERT INTO public.delivery_medium_template (id, alarm_id, delivery_medium_id, subject, body)
VALUES(183, 89, 4, NULL, 'nr.alarm.89.template');

-- alarm_system_mode_settings
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(138, 80, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(139, 80, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(140, 80, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(141, 81, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(142, 81, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(143, 81, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(144, 82, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(145, 82, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(146, 82, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(147, 83, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(148, 83, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(149, 83, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(150, 84, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(151, 84, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(152, 84, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(153, 85, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(154, 85, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(155, 85, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(156, 86, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(157, 86, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(158, 86, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(159, 87, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(160, 87, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(161, 87, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(162, 88, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(163, 88, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(164, 88, 5, false, true, true, false);

INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(165, 89, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(166, 89, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings(id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(167, 89, 5, false, true, true, false);
