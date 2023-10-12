begin;

create table resource_event (
    created timestamp without time zone default current_timestamp not null,
    account_id uuid not null,
    resource_id uuid not null,
    resource_type varchar(36) not null,
    resource_action varchar(36) not null,
    resource_name varchar(256) not null,
    user_name varchar(256) not null,
    user_id uuid not null,
    ip_address inet,
    client_id uuid,
    user_agent varchar(256),
    event_data jsonb not null default '{}'::jsonb,
    UNIQUE(user_id, created, resource_id)
);
create index on resource_event (created desc, account_id);

commit;