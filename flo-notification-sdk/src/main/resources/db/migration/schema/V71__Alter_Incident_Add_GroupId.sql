ALTER TABLE public.incident
  ADD COLUMN group_id uuid;

CREATE INDEX ix_group_id_status_create_at ON public.incident USING btree (group_id, status, create_at DESC NULLS LAST);
CREATE INDEX ix_group_id_create_at ON public.incident USING btree (group_id, create_at DESC NULLS LAST);
