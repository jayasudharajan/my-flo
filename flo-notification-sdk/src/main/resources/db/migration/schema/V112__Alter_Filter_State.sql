CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

ALTER TABLE public.filter_state
  ALTER COLUMN id SET DEFAULT uuid_generate_v4();

ALTER TABLE public.filter_state
  ALTER COLUMN device_id SET DEFAULT uuid_nil(),
  ALTER COLUMN device_id SET NOT NULL;

ALTER TABLE public.filter_state
  ALTER COLUMN incident_id SET DEFAULT uuid_nil(),
  ALTER COLUMN incident_id SET NOT NULL;

ALTER TABLE public.filter_state
  ADD COLUMN location_id uuid NOT NULL DEFAULT uuid_nil(),
  ADD COLUMN user_id uuid NOT NULL DEFAULT uuid_nil();

ALTER TABLE filter_state DROP CONSTRAINT filter_state_unique;

CREATE UNIQUE INDEX ix_filter_state_unique ON public.filter_state USING btree (device_id, location_id, user_id, alarm_id, type);
