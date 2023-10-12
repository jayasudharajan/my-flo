
-- alarm_system_mode_settings
UPDATE public.alarm_system_mode_settings
    SET sms_enabled=false, call_enabled=false
    WHERE system_mode in (2,3) AND alarm_id in (10, 13, 14, 16, 18, 26, 28, 29, 30, 31, 32, 33, 34, 45, 50, 51, 52, 53, 55);

