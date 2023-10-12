INSERT INTO public."action" (id, name, "text", display_on_status, sort, snooze_seconds) VALUES(20, 'Ignore For 5 minutes', 'Yes, for 5 minutes', 3, 6, 300);
INSERT INTO public."action" (id, name, "text", display_on_status, sort, snooze_seconds) VALUES(21, 'Ignore For 30 minutes', 'Yes, for 30 minutes', 3, 7, 1800);

INSERT INTO public.alarm_to_action (alarm_id, action_id) VALUES(100, 4);
INSERT INTO public.alarm_to_action (alarm_id, action_id) VALUES(100, 20);
INSERT INTO public.alarm_to_action (alarm_id, action_id) VALUES(100, 21);
