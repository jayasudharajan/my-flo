--- Alarm System Mode Settings

UPDATE public.alarm_system_mode_settings SET
     alarm_id = 108,
     sms_enabled = false,
     email_enabled = true,
     push_enabled = true,
     call_enabled = NULL
     WHERE id in (220, 221);

UPDATE public.alarm_system_mode_settings SET
     alarm_id = 108,
     sms_enabled = NULL,
     email_enabled = NULL,
     push_enabled = NULL,
     call_enabled = NULL
     WHERE id = 222;