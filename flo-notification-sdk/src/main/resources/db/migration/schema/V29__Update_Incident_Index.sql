DROP INDEX IF EXISTS ix_incident_icd_id_alarm_id_status;

CREATE INDEX ix_incident_icd_id_alarm_id_status_create_at ON public.incident USING btree (icd_id, alarm_id, status, create_at DESC NULLS LAST);