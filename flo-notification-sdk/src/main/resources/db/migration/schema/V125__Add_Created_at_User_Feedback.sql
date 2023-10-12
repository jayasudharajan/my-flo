ALTER TABLE user_feedback
  ADD COLUMN created_at timestamp NOT NULL DEFAULT NOW(),
  ADD COLUMN updated_at timestamp NOT NULL DEFAULT NOW();