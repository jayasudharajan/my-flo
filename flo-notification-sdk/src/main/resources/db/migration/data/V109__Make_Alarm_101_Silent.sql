UPDATE alarm SET user_configurable = false WHERE id = 101;

UPDATE alarm_system_mode_settings SET sms_enabled = NULL, email_enabled = NULL, push_enabled = NULL, call_enabled = NULL WHERE alarm_id = 101;
