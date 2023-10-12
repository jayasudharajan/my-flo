DROP INDEX IF EXISTS ix_incident_icd_id_alarm_id_status_create_at;
CREATE INDEX ix_incident_icd_id_alarm_id_status_reason_create_at ON public.incident USING btree (icd_id, alarm_id, status, reason, create_at DESC NULLS LAST);

DROP INDEX IF EXISTS ix_incident_location_id_alarm_id_status;
CREATE INDEX ix_incident_location_id_alarm_id_status_reason ON public.incident USING btree (location_id, alarm_id, status, reason);