ALTER TABLE public.alarm
    ADD COLUMN should_be_sent_to_cs boolean not null DEFAULT false;