CREATE TABLE mirror_onboarding_log (
    id uuid not null,
    mac_address macaddr not null,
    device_model varchar,
    device_type varchar,
    is_paired boolean,
    location_id uuid,
    nickname varchar,
    puck_configured_at timestamp with time zone,
    revert_minutes int,
    revert_mode varchar,
    revert_scheduled_at timestamp with time zone,
    should_inherit_system_mode boolean,
    target_system_mode varchar,
    target_valve_state varchar,
    event smallint,
    created_at timestamp default now() not null,
    updated_last_time timestamp default now(),

    primary key(id)
);
create index on mirror_onboarding_log (mac_address);
create index on mirror_onboarding_log (created_at, event);