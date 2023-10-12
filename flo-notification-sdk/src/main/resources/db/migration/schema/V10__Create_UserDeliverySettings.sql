create table user_delivery_settings (
    id uuid DEFAULT (md5(((random())::text || (clock_timestamp())::text)))::uuid,
    account_id uuid not null,
    user_id uuid not null,
    location_id uuid not null,
    icd_id uuid not null,
    alarm_system_mode_settings_id integer not null,
    sms_enabled boolean,
    email_enabled boolean,
    push_enabled boolean,
    call_enabled boolean,
    CONSTRAINT user_delivery_settings_pkey PRIMARY KEY (id),
    CONSTRAINT unique_user_delivery_settings UNIQUE (user_id, icd_id, alarm_system_mode_settings_id),
    CONSTRAINT alarm_system_mode_settings_id_fk FOREIGN KEY (alarm_system_mode_settings_id)
        REFERENCES public.alarm_system_mode_settings (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
