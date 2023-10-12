ALTER TABLE public.user_delivery_settings
    ALTER COLUMN account_id DROP NOT NULL,
    ALTER COLUMN location_id DROP NOT NULL;