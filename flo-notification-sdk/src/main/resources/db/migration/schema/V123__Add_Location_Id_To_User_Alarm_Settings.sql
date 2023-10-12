ALTER TABLE user_delivery_settings
  ADD COLUMN location_id uuid NOT NULL DEFAULT uuid_nil();

ALTER TABLE user_delivery_settings
  ALTER COLUMN icd_id SET DEFAULT uuid_nil();