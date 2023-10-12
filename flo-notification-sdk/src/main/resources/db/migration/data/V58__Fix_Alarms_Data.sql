
-- alarm_system_mode_settings
UPDATE public.alarm_system_mode_settings
    SET sms_enabled=NULL, email_enabled=true, push_enabled=true, call_enabled=NULL
    WHERE id=168;

UPDATE public.alarm_system_mode_settings
    SET sms_enabled=NULL, email_enabled=true, push_enabled=true, call_enabled=NULL
    WHERE id=169;

UPDATE public.alarm_system_mode_settings
    SET sms_enabled=NULL, email_enabled=true, push_enabled=true, call_enabled=NULL
    WHERE id=170;