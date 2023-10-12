create table delivery_event (
    id uuid DEFAULT (md5(((random())::text || (clock_timestamp())::text)))::uuid,
    alarm_event_id uuid not null,
    medium integer not null,
    status integer not null,
    info text,
    update_at timestamp not null,
    create_at timestamp not null,
    CONSTRAINT delivery_event_pkey PRIMARY KEY (id),
    CONSTRAINT delivery_event_alarm_event_id_fk FOREIGN KEY (alarm_event_id)
        REFERENCES public.alarm_event (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
