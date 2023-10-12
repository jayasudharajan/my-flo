ALTER TABLE public.alarm
  ADD COLUMN user_configurable boolean;

UPDATE public.alarm SET user_configurable = FALSE;

ALTER TABLE public.alarm
  ALTER COLUMN user_configurable SET NOT NULL;