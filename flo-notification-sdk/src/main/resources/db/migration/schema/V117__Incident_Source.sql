CREATE TABLE public.incident_source (
  id uuid NOT NULL,
  device_id uuid NOT NULL,
  data json NOT NULL,
  created_at timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT incident_source_pk PRIMARY KEY (id)
);

CREATE INDEX ix_incident_source_device_id ON public.incident_source USING btree (device_id);

CREATE INDEX ix_incident_source_created_at ON public.incident_source USING btree (created_at);