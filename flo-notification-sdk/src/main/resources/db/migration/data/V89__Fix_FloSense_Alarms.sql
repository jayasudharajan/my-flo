
UPDATE public.alarm_system_mode_settings
    SET call_enabled=null
    WHERE alarm_id >= 70 AND alarm_id <= 74 AND system_mode != 2;

UPDATE public.alarm_system_mode_settings
    SET call_enabled=true
    WHERE alarm_id >= 70 AND alarm_id <= 74 AND (system_mode = 2 OR system_mode = 3);

UPDATE public.alarm_system_mode_settings
    SET call_enabled=null, sms_enabled=null, push_enabled=null, email_enabled=null
    WHERE alarm_id >= 80 AND alarm_id <= 89 AND system_mode != 2;

UPDATE public.alarm_system_mode_settings
    SET call_enabled=null
    WHERE alarm_id >= 80 AND alarm_id <= 89 AND system_mode = 2;


UPDATE public.user_delivery_settings
    SET call_enabled=null
    WHERE alarm_system_mode_settings_id in (
        SELECT id from public.alarm_system_mode_settings
            WHERE alarm_id >= 70 AND alarm_id <= 74 AND system_mode != 2
    );

UPDATE public.user_delivery_settings
    SET call_enabled=true
    WHERE alarm_system_mode_settings_id in (
        SELECT id from public.alarm_system_mode_settings
            WHERE alarm_id >= 70 AND alarm_id <= 74 AND (system_mode = 2 OR system_mode = 3)
    );

UPDATE public.user_delivery_settings
    SET call_enabled=null, sms_enabled=null, push_enabled=null, email_enabled=null
    WHERE alarm_system_mode_settings_id in (
        SELECT id from public.alarm_system_mode_settings
            WHERE alarm_id >= 80 AND alarm_id <= 89 AND system_mode != 2
    );

UPDATE public.user_delivery_settings
    SET call_enabled=null
    WHERE alarm_system_mode_settings_id in (
        SELECT id from public.alarm_system_mode_settings
            WHERE alarm_id >= 80 AND alarm_id <= 89 AND system_mode = 2
    );