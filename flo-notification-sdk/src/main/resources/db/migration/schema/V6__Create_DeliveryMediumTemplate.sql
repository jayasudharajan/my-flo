create table delivery_medium_template (
    id integer not null PRIMARY KEY,
    alarm_id integer not null,
    delivery_medium_id integer not null,
    subject text,
    body text not null,
    CONSTRAINT delivery_medium_template_alarm_id_fk FOREIGN KEY (alarm_id)
        REFERENCES public.alarm (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
