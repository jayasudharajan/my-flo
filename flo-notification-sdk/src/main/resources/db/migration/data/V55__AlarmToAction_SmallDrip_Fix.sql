DELETE FROM alarm_to_action WHERE alarm_id IN (28, 29, 30, 31);

INSERT INTO alarm_to_action (alarm_id, action_id) SELECT id, 4 FROM alarm WHERE id IN (28, 29, 30, 31);
INSERT INTO alarm_to_action (alarm_id, action_id) SELECT id, 16 FROM alarm WHERE id IN (28, 29, 30, 31);
INSERT INTO alarm_to_action (alarm_id, action_id) SELECT id, 18 FROM alarm WHERE id IN (28, 29, 30, 31);
