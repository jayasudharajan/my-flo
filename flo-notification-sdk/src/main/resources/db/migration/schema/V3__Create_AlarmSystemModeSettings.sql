create table alarm_system_mode_settings (
    id integer not null PRIMARY KEY,
    alarm_id integer not null,
    system_mode integer not null,
    sms_enabled boolean,
    email_enabled boolean,
    push_enabled boolean,
    call_enabled boolean,
    CONSTRAINT alarm_system_mode_settings_alarm_id_fk FOREIGN KEY (alarm_id)
        REFERENCES public.alarm (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
