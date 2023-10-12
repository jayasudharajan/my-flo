create table alarm_to_action (
    alarm_id integer not null,
    action_id integer not null,
    CONSTRAINT alarm_to_action_alarm_id_fk FOREIGN KEY (alarm_id)
        REFERENCES public.alarm (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT alarm_to_action_action_id_fk FOREIGN KEY (action_id)
        REFERENCES public.action (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
