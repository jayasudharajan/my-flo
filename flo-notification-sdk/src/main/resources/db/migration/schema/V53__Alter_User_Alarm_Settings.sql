
ALTER TABLE public.user_alarm_settings
    ADD COLUMN small_drip_sensitivity SMALLINT not null DEFAULT 1;