ALTER TABLE public.alarm
    DROP COLUMN exempted,
    DROP COLUMN sms_supported,
    DROP COLUMN email_supported,
    DROP COLUMN voice_supported,
    DROP COLUMN push_supported;