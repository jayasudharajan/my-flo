ALTER TABLE public.incident_text
  ALTER COLUMN text TYPE json USING text::json;

CREATE INDEX incident_text_created_at ON public.incident_text USING btree (created_at);