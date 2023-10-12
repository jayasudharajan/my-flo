create table alarm (
    id integer not null PRIMARY KEY,
    name text not null,
    severity integer not null,
    is_internal boolean not null,
    send_when_valve_is_closed boolean not null,
    exempted boolean not null,
    enabled boolean not null,
    max_delivery_frequency text not null
);
