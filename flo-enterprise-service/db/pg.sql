begin;

create table test_table (
    id uuid primary key not null,
    mac macaddr not null,
    created timestamp without time zone default current_timestamp not null
);
create index on test_table (mac);

commit;
