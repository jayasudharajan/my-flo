ALTER TABLE user_delivery_settings DROP CONSTRAINT unique_user_delivery_settings;

CREATE UNIQUE INDEX unique_user_delivery_settings ON public.user_delivery_settings USING btree (user_id, icd_id, location_id, alarm_system_mode_settings_id);