UPDATE public.delivery_event
  SET info = NULL;

ALTER TABLE public.delivery_event
  ALTER COLUMN info TYPE json USING info::JSON;;

