CREATE TABLE public.voice_request_log (
  incident_id UUID NOT NULL,
  user_id UUID NOT NULL,
  request_body json,
  CONSTRAINT voice_request_log_pk PRIMARY KEY (incident_id)
);

