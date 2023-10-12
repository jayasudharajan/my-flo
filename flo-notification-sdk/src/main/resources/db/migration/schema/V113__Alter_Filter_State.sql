DROP INDEX ix_filter_state_unique;

CREATE UNIQUE INDEX ix_filter_state_unique ON public.filter_state USING btree (alarm_id, type, device_id, location_id, user_id);

CREATE INDEX ix_filter_state_expiration ON public.filter_state USING btree (alarm_id, type, expiration, device_id, location_id, user_id);
