begin;

create table device_registry (
    id uuid primary key not null,
    mac macaddr not null,
    created timestamp without time zone default current_timestamp not null
);
create index on device_registry (mac);

create table user_registry (
    id uuid primary key not null,
    created timestamp without time zone default current_timestamp not null
);

create table device_clean_rm (
     id uuid primary key not null,
     mac macaddr not null,
     created timestamp without time zone default current_timestamp not null
);
create index on device_clean_rm (mac);

commit;