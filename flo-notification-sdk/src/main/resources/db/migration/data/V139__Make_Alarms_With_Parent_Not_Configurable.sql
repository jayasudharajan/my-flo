UPDATE alarm
SET user_configurable = false
WHERE parent_id IS NOT NULL;