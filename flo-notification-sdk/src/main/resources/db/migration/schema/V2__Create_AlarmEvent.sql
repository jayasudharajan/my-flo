create table alarm_event (
    id uuid DEFAULT (md5(((random())::text || (clock_timestamp())::text)))::uuid,
    alarm_id integer not null,
    icd_id uuid not null,
    status integer not null,
    snooze_to timestamp,
    location_id uuid not null,
    system_mode integer not null,
    update_at timestamp not null,
    create_at timestamp not null,
    CONSTRAINT alarm_event_pkey PRIMARY KEY (id),
    CONSTRAINT alarm_event_alarm_id_fk FOREIGN KEY (alarm_id)
        REFERENCES public.alarm (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
