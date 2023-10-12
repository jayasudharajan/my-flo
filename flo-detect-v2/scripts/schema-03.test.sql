/*
existing table: flodetect_events
+----------------------+-----------------------------+----------------------------------------------------------------+
| Column               | Type                        | Modifiers                                                      |
|----------------------+-----------------------------+----------------------------------------------------------------|
| id                   | uuid                        |  not null default uuid_generate_v4()                           |
| device_id            | character(12)               |  not null                                                      |
| start                | timestamp without time zone |  not null                                                      |
| end                  | timestamp without time zone |  not null                                                      |
| duration             | double precision            |  not null                                                      |
| gallons_total        | double precision            |  not null                                                      |
| incident_id          | uuid                        |  not null default '00000000-0000-0000-0000-000000000000'::uuid |
| created              | timestamp without time zone |  not null                                                      |
| updated              | timestamp without time zone |  not null                                                      |
| predicted_fixture_id | integer                     |  not null                                                      |
| feedback_fixture_id  | integer                     |  not null default 0                                            |
| feedback_user_id     | uuid                        |  not null default '00000000-0000-0000-0000-000000000000'::uuid |
| raw                  | json                        |  not null                                                      |
+----------------------+-----------------------------+----------------------------------------------------------------+
Indexes:
    "flodetect_events_pk" PRIMARY KEY, btree (id)
    "flodetect_events_unique_index" UNIQUE, btree (device_id, start, "end", predicted_fixture_id)
    "flodetect_events_eventhandler" btree (device_id, start DESC, "end", gallons_total, duration)
    "flodetect_events_feedback_fixture_id_index" btree (feedback_fixture_id)
    "flodetect_events_predicted_fixture_id_index" btree (predicted_fixture_id)
    "flodetect_events_start_index" btree (start)
*/
create table flodetect_events_2 (
  id uuid not null default uuid_generate_v4(),
  device_id macaddr not null,
  "start" timestamp without time zone not null,
  "end" timestamp without time zone not null,
  duration real not null,
  gallons_total real not null,
  incident_id uuid not null default '00000000-0000-0000-0000-000000000000'::uuid,
  created timestamp without time zone not null,
  updated timestamp without time zone not null,
  predicted_fixture_id integer not null,
  feedback_fixture_id integer not null default 0,
  feedback_user_id uuid not null default '00000000-0000-0000-0000-000000000000'::uuid,
  raw json not null,
  primary key (id)
);

create unique index "fdef_unique_idx" on flodetect_events_feedback (device_id, "start", "end", predicted_fixture_id);
create index "fdef_idx_feedback_fixture_id" on flodetect_events_feedback (feedback_fixture_id);
create index "fdef_idx_predicted_fixture_id" on flodetect_events_feedback (predicted_fixture_id);
create index "fdef_idx_start" on flodetect_events_feedback (start);

-- migration of existing data
insert into flodetect_events_feedback select * from flodetect_events_feedback_view;