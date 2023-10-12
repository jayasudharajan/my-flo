
update public.alarm
    set user_configurable=true
    where id=11;


update public.alarm_system_mode_settings
    set call_enabled=NULL, email_enabled=true, push_enabled=true, sms_enabled=false
    where alarm_id in (12, 14);