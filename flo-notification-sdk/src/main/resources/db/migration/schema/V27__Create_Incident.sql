CREATE TABLE public.incident (
	id uuid NOT NULL DEFAULT md5(random()::text || clock_timestamp()::text)::uuid,
	alarm_id int4 NOT NULL,
	icd_id uuid NOT NULL,
	status int4 NOT NULL,
	snooze_to timestamp NULL,
	location_id uuid NOT NULL,
	system_mode int4 NOT NULL,
	update_at timestamp NOT NULL,
	create_at timestamp NOT NULL,
	reason int4 NULL,
	account_id uuid NOT NULL,
	data_values json NULL,
	display_title text NOT NULL,
	display_message text NOT NULL,
	display_title_localized text NULL,
	display_message_localized text NULL,
	display_locale text NOT NULL,
	CONSTRAINT incident_new_pkey PRIMARY KEY (id)
);

CREATE INDEX ix_incident_alarm_id_icd_id_snoozed_created_at ON public.incident USING btree (alarm_id, icd_id, snooze_to, create_at DESC NULLS LAST);
CREATE INDEX ix_incident_icd_id_alarm_id_status ON public.incident USING btree (icd_id, alarm_id, status);
CREATE INDEX ix_incident_location_id_alarm_id_status ON public.incident USING btree (location_id, alarm_id, status);
