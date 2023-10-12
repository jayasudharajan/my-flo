-- Delete all actions except small drip alarms since these are properly configured.
DELETE FROM alarm_to_action WHERE alarm_id NOT IN (28, 29, 30, 31);

-- Insert Action 1 to CRITICAL and WARNING alarms.
INSERT INTO alarm_to_action (alarm_id, action_id) SELECT id, 1 FROM alarm where severity IN (1, 2) AND is_internal = FALSE;
-- Insert Action 4 to CRITICAL and WARNING alarms.
INSERT INTO alarm_to_action (alarm_id, action_id) SELECT id, 4 FROM alarm where severity IN (1, 2) AND is_internal = FALSE;
-- Insert Action 6 to CRITICAL and WARNING alarms.
INSERT INTO alarm_to_action (alarm_id, action_id) SELECT id, 6 FROM alarm where severity IN (1, 2) AND is_internal = FALSE;
