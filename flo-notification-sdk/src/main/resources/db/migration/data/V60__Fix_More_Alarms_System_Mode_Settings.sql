
-- alarm_system_mode_settings
UPDATE public.alarm_system_mode_settings
    SET email_enabled=NULL, push_enabled=NULL, call_enabled=NULL, sms_enabled=NULL
    WHERE system_mode = 3 AND alarm_id in (51, 52, 53);

UPDATE public.alarm_system_mode_settings
    SET call_enabled=NULL
    WHERE system_mode = 2 AND alarm_id in (51, 52, 53);


UPDATE public.alarm_system_mode_settings
    SET email_enabled=NULL, push_enabled=NULL, call_enabled=NULL, sms_enabled=NULL
    WHERE system_mode = 2 AND alarm_id = 55;