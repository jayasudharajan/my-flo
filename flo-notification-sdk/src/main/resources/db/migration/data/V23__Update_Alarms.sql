UPDATE public.alarm
	SET sms_supported = TRUE,
      email_supported = TRUE,
      push_supported = TRUE;

UPDATE public.alarm
	SET voice_supported = TRUE
	WHERE severity = 1;

UPDATE public.alarm
  SET parent_id = 28
  WHERE id IN (29, 30, 31);

UPDATE public.alarm
  SET display_name = 'Health Test Skipped'
  WHERE id IN (4);

UPDATE public.alarm
  SET display_name = 'Health Test Successful'
  WHERE id IN (5, 34);

UPDATE public.alarm
  SET display_name = 'Fast Water Flow'
  WHERE id IN (10);

UPDATE public.alarm
  SET display_name = 'High Water Usage'
  WHERE id IN (11);

UPDATE public.alarm
  SET display_name = 'Hot Water'
  WHERE id IN (14);

UPDATE public.alarm
  SET display_name = 'Freeze Warning'
  WHERE id IN (13);

UPDATE public.alarm
  SET display_name = 'High Water Pressure'
  WHERE id IN (16);

UPDATE public.alarm
  SET display_name = 'Low Water Pressure'
  WHERE id IN (15);

UPDATE public.alarm
  SET display_name = 'Valve Error'
  WHERE id IN (18);

UPDATE public.alarm
  SET display_name = 'General System Error'
  WHERE id IN (22);

UPDATE public.alarm
  SET display_name = 'Device Memory Error'
  WHERE id IN (23);

UPDATE public.alarm
  SET display_name = 'Extended Water Use'
  WHERE id IN (26);

UPDATE public.alarm
  SET display_name = 'Small Drip Detected'
  WHERE id IN (28, 29, 30, 31);

UPDATE public.alarm
  SET display_name = 'Health Test Interrupted'
  WHERE id IN (32, 40, 41);

UPDATE public.alarm
  SET display_name = 'Device Offline'
  WHERE id IN (33);

UPDATE public.alarm
  SET display_name = 'Valve Open'
  WHERE id IN (35, 47);

UPDATE public.alarm
  SET display_name = 'Valve Close'
  WHERE id IN (36);

UPDATE public.alarm
  SET display_name = 'Health Test Started'
  WHERE id IN (38);

UPDATE public.alarm
  SET display_name = 'Health Test Delayed'
  WHERE id IN (42);

UPDATE public.alarm
  SET display_name = 'Mode Change'
  WHERE id IN (43);

UPDATE public.alarm
  SET display_name = 'Alert Resolved'
  WHERE id IN (45);

UPDATE public.alarm
  SET display_name = 'Device Online'
  WHERE id IN (46);

UPDATE public.alarm
  SET display_name = 'Device Still Offline'
  WHERE id IN (50);

UPDATE public.alarm
  SET display_name = 'Water System Shutoff'
  WHERE id IN (51, 52, 53);

UPDATE public.alarm
  SET display_name = 'Low GPM Fluctuating Water Pattern Detected'
  WHERE id IN (54);

UPDATE public.alarm
  SET display_name = 'Device Installed'
  WHERE id IN (5001);

