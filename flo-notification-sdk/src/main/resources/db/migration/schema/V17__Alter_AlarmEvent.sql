ALTER TABLE public.alarm_event
    ADD COLUMN account_id uuid;

UPDATE public.alarm_event
	SET account_id=(md5(((random())::text || (clock_timestamp())::text)))::uuid;

ALTER TABLE public.alarm_event
    ALTER COLUMN account_id SET NOT NULL;