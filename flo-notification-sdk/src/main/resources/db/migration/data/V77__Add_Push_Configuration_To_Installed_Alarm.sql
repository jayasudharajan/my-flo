UPDATE public.alarm
  SET push_configuration = '{"is_silent":true,"app_link":"floapp://needs_install"}'::json
  WHERE id = 5001;