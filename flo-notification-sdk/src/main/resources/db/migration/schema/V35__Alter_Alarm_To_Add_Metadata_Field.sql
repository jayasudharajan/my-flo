ALTER TABLE public.alarm
    ADD COLUMN metadata json not null DEFAULT '{}';
