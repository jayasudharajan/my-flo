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


new table based of the old view: flodetect_events_feedback_view
+----------------------+-----------------------------+-------------+-----------+---------------+
| Column               | Type                        | Modifiers   | Storage   | Description   |
|----------------------+-----------------------------+-------------+-----------+---------------|
| id                   | uuid                        |             | plain     | <null>        |
| device_id            | character(12)               |             | extended  | <null>        |
| start                | timestamp without time zone |             | plain     | <null>        |
| end                  | timestamp without time zone |             | plain     | <null>        |
| duration             | double precision            |             | plain     | <null>        |
| gallons_total        | double precision            |             | plain     | <null>        |
| incident_id          | uuid                        |             | plain     | <null>        |
| created              | timestamp without time zone |             | plain     | <null>        |
| updated              | timestamp without time zone |             | plain     | <null>        |
| predicted_fixture_id | integer                     |             | plain     | <null>        |
| feedback_fixture_id  | integer                     |             | plain     | <null>        |
| feedback_user_id     | uuid                        |             | plain     | <null>        |
| raw                  | json                        |             | extended  | <null>        |
+----------------------+-----------------------------+-------------+-----------+---------------+
View definition:
 CREATE VIEW flodetect_events_feedback_view AS
 SELECT flodetect_events.id,
    flodetect_events.device_id,
    flodetect_events.start,
    flodetect_events."end",
    flodetect_events.duration,
    flodetect_events.gallons_total,
    flodetect_events.incident_id,
    flodetect_events.created,
    flodetect_events.updated,
    flodetect_events.predicted_fixture_id,
    flodetect_events.feedback_fixture_id,
    flodetect_events.feedback_user_id,
    flodetect_events.raw
   FROM flodetect_events
  WHERE flodetect_events.feedback_fixture_id > 0;
*/
create table flodetect_events_feedback (
  id uuid not null default uuid_generate_v4(),
  device_id character(12) not null,
  "start" timestamp without time zone not null,
  "end" timestamp without time zone not null,
  duration double precision not null,
  gallons_total double precision not null,
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