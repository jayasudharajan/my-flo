DELETE FROM public.group_role_delivery_settings grds
    WHERE grds.alarm_system_mode_settings_id in (
        SELECT asms.id FROM public.alarm_system_mode_settings asms
            WHERE alarm_id = 14
   );

DELETE FROM public.user_delivery_settings uds
    WHERE uds.alarm_system_mode_settings_id in (
        SELECT asms.id FROM public.alarm_system_mode_settings asms
            WHERE alarm_id = 14
   );

DELETE FROM public.alarm_system_mode_settings
  WHERE alarm_id = 14;

DELETE FROM public.alarm
  WHERE id = 14;