CREATE INDEX ix_delivery_event_external_id ON public.delivery_event (external_id);

CREATE INDEX ix_delivery_event_alarm_event_id_user_id_medium ON public.delivery_event (alarm_event_id, user_id, medium);

DROP INDEX IF EXISTS ix_delivery_event_alarm_event_id;