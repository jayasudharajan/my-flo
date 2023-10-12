create table action (
    id integer not null PRIMARY KEY,
    name text not null,
    text text not null,
    display_on_status integer not null,
    sort integer not null
);
