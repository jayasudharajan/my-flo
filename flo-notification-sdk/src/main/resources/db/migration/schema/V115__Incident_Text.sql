CREATE TABLE public.incident_text (
  incident_id uuid NOT NULL,
  device_id uuid NOT NULL,
  lang text NOT NULL,
  text text NOT NULL,
  created_at timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT incident_text_pk PRIMARY KEY (incident_id)
);

CREATE INDEX incident_text_device_id ON public.incident_text USING btree (device_id);