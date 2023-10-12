
UPDATE public.delivery_medium_template
  SET body = concat('nr.alarm.', alarm_id, '.template');

UPDATE public.delivery_medium_template
  SET subject = concat('nr.alarm.', alarm_id, '.subject')
  WHERE delivery_medium_id = 3;


UPDATE public.delivery_medium_template
  SET subject = NULL
  WHERE delivery_medium_id != 3;