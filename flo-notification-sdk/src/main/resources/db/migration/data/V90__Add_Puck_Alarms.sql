-- Alarm

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(100, 'water_detected', 1, false, false, true, '0 hours', NULL, '{}'::json, true);

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(101, 'water_shutoff_by_detector', 1, false, false, true, '0 hours', NULL, '{}'::json, true);

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(102, 'high_humidity', 2, false, true, true, '1 hours', NULL, '{}'::json, true);

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(103, 'low_humidity', 2, false, true, true, '1 hours', NULL, '{}'::json, true);

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(104, 'high_temperature', 2, false, true, true, '1 hours', NULL, '{}'::json, true);

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(105, 'low_temperature', 2, false, true, true, '1 hours', NULL, '{}'::json, true);

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(106, 'low_battery', 2, false, true, true, '1 hours', NULL, '{}'::json, true);

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(107, 'device_offline', 2, false, true, true, '1 hours', NULL, '{}'::json, true);

INSERT INTO public.alarm (id, name, severity, is_internal, send_when_valve_is_closed, enabled, max_delivery_frequency, parent_id, metadata, user_configurable)
      VALUES(108, 'device_back_online', 3, false, true, true, '0 hours', NULL, '{}'::json, false);


--- Alarm System Mode Settings

INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(193, 100, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(194, 100, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(195, 100, 5, NULL, NULL, NULL, NULL);


INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(196, 101, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(197, 101, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(198, 101, 5, NULL, NULL, NULL, NULL);


INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(199, 102, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(200, 102, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(201, 102, 5, false, true, true, NULL);


INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(202, 102, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(203, 102, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(204, 102, 5, false, true, true, NULL);


INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(205, 103, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(206, 103, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(207, 103, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(208, 104, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(209, 104, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(210, 104, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(211, 105, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(212, 105, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(213, 105, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(214, 106, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(215, 106, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(216, 106, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(217, 107, 2, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(218, 107, 3, false, true, true, NULL);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(219, 107, 5, false, true, true, NULL);

INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(220, 107, 2, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(221, 107, 3, false, true, true, false);
INSERT INTO public.alarm_system_mode_settings (id, alarm_id, system_mode, sms_enabled, email_enabled, push_enabled, call_enabled)
VALUES(222, 107, 5, false, NULL, NULL, NULL);