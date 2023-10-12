CREATE TABLE public.user_feedback_options (
  id int4 NOT NULL,
  feedback json NOT NULL,
  options_key_list json NOT NULL,

  CONSTRAINT user_feedback_options_pk PRIMARY KEY (id)
);

CREATE TABLE public.user_feedback (
  incident_id uuid NOT NULL,
  user_id uuid NOT NULL,
  feedback json NOT NULL,

  CONSTRAINT user_feedback_pk PRIMARY KEY (incident_id)
);

ALTER TABLE public.alarm
  ADD COLUMN user_feedback_options_id int4 NULL;