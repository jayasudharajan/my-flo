begin;

create table if not exists adc_user_registry (
    flo_user_id uuid primary key not null,
    flo_client_id varchar(64) not null,
    updated timestamp without time zone default current_timestamp not null,
    created timestamp without time zone default current_timestamp not null
);

ALTER TABLE adc_user_registry ADD COLUMN version integer;

create table if not exists adc_device (
    id uuid primary key not null,
    mac macaddr not null,
    user_id uuid not null,
    loc_id uuid not null
);
create index on adc_device (mac);
create index on adc_device (user_id);
-- create index on adc_device (loc_id);

commit;