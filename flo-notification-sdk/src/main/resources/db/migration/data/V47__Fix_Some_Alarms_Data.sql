
UPDATE public.alarm SET enabled = true WHERE id in (5400, 48, 56, 57, 58, 59, 60, 61, 62, 55);

UPDATE public.alarm SET is_internal = false WHERE id < 5000;

UPDATE public.alarm SET max_delivery_frequency = '0 hours' WHERE id in (56, 59, 60, 61, 62);
