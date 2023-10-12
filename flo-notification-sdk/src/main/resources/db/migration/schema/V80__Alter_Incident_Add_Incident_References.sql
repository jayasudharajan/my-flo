ALTER TABLE public.incident
  ADD COLUMN old_incident_ref uuid,
  ADD COLUMN new_incident_ref uuid;
