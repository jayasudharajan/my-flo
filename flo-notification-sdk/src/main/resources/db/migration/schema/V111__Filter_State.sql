CREATE TABLE public.filter_state (
  id uuid NOT NULL DEFAULT md5(random()::text || clock_timestamp()::text)::uuid,
  alarm_id int4 NOT NULL,
  type int4 NOT NULL,
  device_id uuid NULL,
  incident_id uuid NULL,
  expiration timestamp NOT NULL,
  created_at timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT filter_state_pk PRIMARY KEY (id),
  CONSTRAINT filter_state_unique UNIQUE (device_id, alarm_id, type)
);