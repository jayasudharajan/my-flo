ALTER TABLE public.alarm
    ADD COLUMN description text;

UPDATE public.alarm
	SET description='';

ALTER TABLE public.alarm
    ALTER COLUMN description SET NOT NULL;