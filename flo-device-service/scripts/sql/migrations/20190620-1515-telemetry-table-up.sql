CREATE TABLE telemetry (
  device_id varchar,
  water_flow float,
  water_flow_amount float,
  temperature float,
  pressure float,
  sw1 smallint,
  sw2 smallint,
  timestamp bigint,
  system_mode smallint,
  hts smallint,
  rssi smallint,
  valve_state smallint,
  created_time timestamp with time zone default now() not null,
  updated_time timestamp with time zone default now() not null,
  primary key(device_id)
);