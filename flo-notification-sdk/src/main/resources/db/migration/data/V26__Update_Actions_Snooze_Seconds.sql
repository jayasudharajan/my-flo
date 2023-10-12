
UPDATE public.action
  SET snooze_seconds = 7200
  WHERE id = 1;

UPDATE public.action
  SET snooze_seconds = 86400
  WHERE id = 6;

UPDATE public.action
  SET snooze_seconds = 2592000
  WHERE id = 18;

UPDATE public.action
  SET snooze_seconds = 604800
  WHERE id = 16;