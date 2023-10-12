
ALTER TABLE public.user_alarm_settings
    ADD COLUMN alarms_muted BOOLEAN NOT NULL DEFAULT false;