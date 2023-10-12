UPDATE alarm_system_mode_settings
SET
  email_enabled = NULL,
  push_enabled = NULL,
  sms_enabled = NULL,
  call_enabled = NULL
WHERE system_mode = 5 AND
  alarm_id IN (3, 4, 5, 32, 38, 39, 40, 41, 42, 56);