UPDATE alert_feedback_flow SET flow_tags = REPLACE(flow_tags::text, 'Flo device', 'Flo by Moen device')::json;

UPDATE user_feedback_options SET options_key_list = REPLACE(options_key_list::text, 'Flo device', 'Flo by Moen device')::json;