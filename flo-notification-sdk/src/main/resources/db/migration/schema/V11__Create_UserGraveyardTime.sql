create table user_graveyard_time (
    id uuid DEFAULT (md5(((random())::text || (clock_timestamp())::text)))::uuid,
    account_id uuid not null,
    user_id uuid not null,
    starts_at text not null,
    ends_at text not null,
    allow_email boolean not null,
    allow_sms boolean not null,
    allow_push boolean not null,
    allow_call boolean not null,
    when_severity_is text not null,
    CONSTRAINT user_graveyard_time_pkey PRIMARY KEY (id)
);
