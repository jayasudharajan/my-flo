# CLOUD-4442
IF NOT EXISTS (SELECT FROM pg_catalog.pg_tables WHERE tablename  = 'deleted_devices') THEN

CREATE TABLE deleted_devices (
  id varchar not null,
  location_id varchar,
  device_id varchar,
  device_data_raw JSONB not null,
  deleted_time timestamp with time zone default now() not null,
  primary key(id)
);

create index on deleted_devices (device_id);

END IF;