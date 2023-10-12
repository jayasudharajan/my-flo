DROP TABLE IF EXISTS devices cascade;
CREATE TABLE devices (
  device_id varchar,
  fw_ver varchar,
  is_connected boolean,
  fw_properties_raw json,
  created_time timestamp with time zone default now() not null,
  last_heard_from_time timestamp with time zone default now() not null,
  updated_time timestamp with time zone default now() not null,
  primary key(device_id)
);

CREATE TABLE fw_feedback_loop (
  request_id varchar,
  device_id varchar,
  ack boolean,
  primary key(request_id)
);