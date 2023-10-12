create table support_option (
    id integer not null PRIMARY KEY,
    alarm_id integer not null,
    action_path text not null,
    action_type integer not null,
    sort integer not null,
    text text not null,
    CONSTRAINT support_option_alarm_id_fk FOREIGN KEY (alarm_id)
        REFERENCES public.alarm (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
