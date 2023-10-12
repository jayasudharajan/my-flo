UPDATE public.alarm
  SET user_configurable = true
  WHERE id = 28;


UPDATE public.alarm
  SET user_configurable = false
  WHERE id in (29, 30, 31);