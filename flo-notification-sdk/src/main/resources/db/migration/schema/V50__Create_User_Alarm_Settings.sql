CREATE TABLE public.user_alarm_settings (
  user_id UUID NOT NULL,
  icd_id UUID NOT NULL,
  flo_sense_level SMALLINT,

	CONSTRAINT user_alarm_settings_pk PRIMARY KEY (user_id, icd_id)
);

