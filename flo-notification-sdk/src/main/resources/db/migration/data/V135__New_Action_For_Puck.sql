INSERT INTO public."action" (id, name, "text", display_on_status, sort, snooze_seconds) VALUES(22, 'Ignore For 6 hours', 'Yes, for 6 hours', 3, 8, 21600);

INSERT INTO public.alarm_to_action (alarm_id, action_id) VALUES(100, 22);
