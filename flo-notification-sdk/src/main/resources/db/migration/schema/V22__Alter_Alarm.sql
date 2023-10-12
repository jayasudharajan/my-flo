-- Delivery Mediums configuration

ALTER TABLE public.alarm
  ADD COLUMN sms_supported boolean NULL,
  ADD COLUMN email_supported boolean NULL,
  ADD COLUMN voice_supported boolean NULL,
  ADD COLUMN push_supported boolean NULL;

UPDATE public.alarm
	SET sms_supported = FALSE,
      email_supported = FALSE,
      voice_supported = FALSE,
      push_supported = FALSE;

ALTER TABLE public.alarm
  ALTER COLUMN sms_supported SET NOT NULL,
  ALTER COLUMN email_supported SET NOT NULL,
  ALTER COLUMN voice_supported SET NOT NULL,
  ALTER COLUMN push_supported SET NOT NULL;

-- Parent Alarm

ALTER TABLE public.alarm
  ADD COLUMN parent_id integer NULL;

ALTER TABLE public.alarm
  ADD CONSTRAINT alarm_parent_id_fk FOREIGN KEY (parent_id)
  REFERENCES public.alarm (id) MATCH SIMPLE
    ON UPDATE RESTRICT
    ON DELETE RESTRICT;

-- Display Name

ALTER TABLE public.alarm
  ADD COLUMN display_name text NULL;

UPDATE public.alarm
	SET display_name = '';

ALTER TABLE public.alarm
  ALTER COLUMN display_name SET NOT NULL;