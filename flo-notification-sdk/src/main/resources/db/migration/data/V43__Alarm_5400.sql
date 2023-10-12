UPDATE public.alarm SET id = 5400 where id = 5004;

UPDATE public.delivery_medium_template SET alarm_id = 5400, body = 'nr.alarm.5400.template' WHERE id = 151;
UPDATE public.delivery_medium_template SET alarm_id = 5400, body = 'nr.alarm.5400.template', subject = 'nr.alarm.5400.subject' WHERE id = 152;
UPDATE public.delivery_medium_template SET alarm_id = 5400, body = 'nr.alarm.5400.template' WHERE id = 153;

UPDATE public.alarm_system_mode_settings SET alarm_id = 5400 WHERE alarm_id = 5004;