DROP TABLE IF EXISTS types cascade;
CREATE TABLE types (
                        type varchar,
                        description varchar default '',
                        created timestamp with time zone default now() not null,
                        updated timestamp with time zone default now() not null,
                        primary key(type)
);