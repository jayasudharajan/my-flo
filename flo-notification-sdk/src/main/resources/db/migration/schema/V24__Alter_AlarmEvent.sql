ALTER TABLE public.alarm_event
    ADD COLUMN data_values json;

ALTER TABLE public.alarm_event
    ADD COLUMN display_title text;

ALTER TABLE public.alarm_event
    ADD COLUMN display_message text;

ALTER TABLE public.alarm_event
    ADD COLUMN display_title_localized text;

ALTER TABLE public.alarm_event
    ADD COLUMN display_message_localized text;

ALTER TABLE public.alarm_event
    ADD COLUMN display_locale text;

UPDATE public.alarm_event SET display_locale='en-us';

UPDATE public.alarm_event SET display_title=al.display_name
FROM (SELECT id, display_name FROM public.alarm) AS al
WHERE public.alarm_event.alarm_id = al.id;

UPDATE public.alarm_event SET display_message='You have a ' || LOWER(display_name) || ' detected...'
FROM (SELECT id, display_name FROM public.alarm) AS al
WHERE public.alarm_event.alarm_id = al.id;

UPDATE public.alarm_event SET data_values = '{}';

ALTER TABLE public.alarm_event
    ALTER COLUMN display_title SET NOT NULL;

ALTER TABLE public.alarm_event
    ALTER COLUMN display_message SET NOT NULL;

ALTER TABLE public.alarm_event
    ALTER COLUMN display_locale SET NOT NULL;