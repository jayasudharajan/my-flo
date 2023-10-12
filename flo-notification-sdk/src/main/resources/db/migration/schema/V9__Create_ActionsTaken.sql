create table actions_taken (
    id integer not null PRIMARY KEY,
    alarm_id integer not null,
    icd_id uuid not null,
    user_id uuid not null,
    action_id integer not null,
    last_event_id uuid not null,
    action integer not null,
    expires_at timestamp not null,
    updated_at timestamp not null,
    created_at timestamp not null,
    CONSTRAINT actions_taken_alarm_id_fk FOREIGN KEY (alarm_id)
        REFERENCES public.alarm (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
