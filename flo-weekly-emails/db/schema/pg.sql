begin;

-- create table & index
create table email_schedule (
    id varchar(64) primary key not null,
    email_type smallint default 0 not null,
    params json,
    ok_count integer default 0 not null,
    err_count integer default 0 not null,
    completed timestamp without time zone,
    created timestamp without time zone default current_timestamp not null
);
create index on email_schedule (created desc, email_type);

-- create table & indices
create table email_queued (
    id bigserial primary key not null,
    schedule_id varchar(64),
    loc_id uuid not null,
    user_id uuid not null,
    email varchar(128) not null,
    email_type smallint default 0 not null,
    template_id varchar(128) not null,
    template_data json,
    queue_dt timestamp without time zone default current_timestamp not null,
    queue_req json,
    error_week smallint,
    error text
);
-- error-week should be yyww (year 20 week 00-52) or null (which is not indexed)
-- when error text is null, error_week is also null. We use this to fetch errors

create index on email_queued (queue_dt desc, email_type, loc_id);
-- equivalent of mongodb sparse index
create index on email_queued (error_week desc) WHERE error_week is not null;
create index on email_queued (schedule_id desc, email) WHERE schedule_id is not null;

commit;