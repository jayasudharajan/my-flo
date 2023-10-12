CREATE TABLE public.alert_feedback_flow (
	alarm_id int4 NOT NULL,
	system_mode int4 NOT NULL,
	flow json NOT NULL,
	flow_tags json NOT NULL,
	CONSTRAINT alert_feedback_flow_pk PRIMARY KEY (alarm_id, system_mode)
);