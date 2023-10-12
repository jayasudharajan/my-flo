DELETE FROM user_delivery_settings uds 
  WHERE uds.alarm_system_mode_settings_id IN (
    SELECT id FROM alarm_system_mode_settings asms WHERE asms.alarm_id IN (29, 30, 31)
  );

