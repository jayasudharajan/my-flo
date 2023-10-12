
ALTER TABLE public.user_delivery_settings
  ADD COLUMN is_muted BOOLEAN NOT NULL DEFAULT false;