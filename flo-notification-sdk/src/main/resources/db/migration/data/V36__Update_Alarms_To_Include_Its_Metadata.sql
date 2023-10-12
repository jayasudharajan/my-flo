
UPDATE public.alarm
  SET metadata = '{"leakLossMinGal":50.0,"leakLossMaxGal":360.0}'::json
  WHERE id = 28;

UPDATE public.alarm
  SET metadata = '{"leakLossMinGal":5.0,"leakLossMaxGal":50.0}'::json
  WHERE id = 29;

UPDATE public.alarm
  SET metadata = '{"leakLossMinGal":1.0,"leakLossMaxGal":5.0}'::json
  WHERE id = 30;

UPDATE public.alarm
  SET metadata = '{"leakLossMinGal":0.015625,"leakLossMaxGal":1.0}'::json
  WHERE id = 31;