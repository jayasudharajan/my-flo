
update public.alarm_system_mode_settings
    set sms_enabled=false
    where alarm_id in (15, 22, 23, 57);