ALTER TABLE public.incident
  DROP COLUMN display_title,
  DROP COLUMN display_message,
  DROP COLUMN display_title_localized,
  DROP COLUMN display_message_localized,
  DROP COLUMN display_locale;