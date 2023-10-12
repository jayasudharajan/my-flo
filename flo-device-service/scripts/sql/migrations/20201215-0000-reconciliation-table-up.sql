CREATE TABLE reconciliation (
   id serial not null,
   level_type smallint not null,
   entity_id varchar(36) not null,
   changed timestamp without time zone default now() not null,   
   new_target varchar(12) not null,
   context JSONB not null,
   reason varchar(64),
   primary key(id)
);
create index on reconciliation (changed, entity_id);