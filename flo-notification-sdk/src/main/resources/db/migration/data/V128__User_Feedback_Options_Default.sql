ALTER TABLE public.user_feedback_options
  ALTER COLUMN options_key_list SET DEFAULT '[]'::json;

UPDATE public.user_feedback_options SET options_key_list = '[]'::json WHERE id = 2;