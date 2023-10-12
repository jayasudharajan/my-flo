-- Make Health Test alarms user configurable
UPDATE alarm
SET user_configurable = true
WHERE id IN (3, 5, 32, 38, 39, 42);

-- Parent/Child relationship
UPDATE alarm
SET parent_id = 32
WHERE id IN (40, 41);

UPDATE alarm
SET parent_id = 3
WHERE id IN (4, 56);

UPDATE alarm
SET parent_id = 5
WHERE id IN (34);

-- Make settings consistent across all Health Test alarms
UPDATE alarm
SET max_delivery_frequency = '0 hours'
WHERE id IN (3, 4, 5, 32, 34, 38, 39, 40, 41, 42, 56);

UPDATE alarm_system_mode_settings
SET sms_enabled = false
WHERE sms_enabled IS NULL AND
  system_mode != 5 AND
  alarm_id IN (3, 4, 5, 32, 34, 38, 39, 40, 41, 42, 56);

UPDATE alarm_system_mode_settings
SET email_enabled = false
WHERE email_enabled IS NULL AND
  system_mode != 5 AND
  alarm_id IN (3, 4, 5, 32, 34, 38, 39, 40, 41, 42, 56);

UPDATE alarm_system_mode_settings
SET push_enabled = false
WHERE push_enabled IS NULL AND
  system_mode != 5 AND
  alarm_id IN (3, 4, 5, 32, 34, 38, 39, 40, 41, 42, 56);

-- Disable Call for all Health Test alarms
UPDATE alarm_system_mode_settings
SET call_enabled = NULL
WHERE alarm_id IN (3, 4, 5, 32, 34, 38, 39, 40, 41, 42, 56);

-- Same Settings for children alarms
UPDATE alarm_system_mode_settings
SET
  email_enabled = true,
  push_enabled = true
WHERE alarm_id IN (32, 40, 41) AND
  system_mode != 5 AND
  account_type = 'personal';

UPDATE alarm_system_mode_settings
SET
  email_enabled = true,
  push_enabled = true
WHERE alarm_id IN (3, 4, 56) AND
  system_mode != 5 AND
  account_type = 'personal';

UPDATE alarm_system_mode_settings
SET
  email_enabled = true,
  push_enabled = true
WHERE alarm_id IN (5, 34) AND
  system_mode != 5 AND
  account_type = 'personal';

-- Delete user delivery settings for children alarms
DELETE FROM user_delivery_settings uds
WHERE uds.alarm_system_mode_settings_id IN (
  SELECT id
  FROM alarm_system_mode_settings asms
  WHERE asms.alarm_id
  IN (4, 34, 40, 41, 56)
);

-- Disable Call for all Health Test alarms
UPDATE user_delivery_settings
SET call_enabled = NULL
WHERE alarm_system_mode_settings_id IN (
  SELECT id
  FROM alarm_system_mode_settings asms
  WHERE asms.alarm_id IN (3, 4, 5, 32, 34, 38, 39, 40, 41, 42, 56)
);