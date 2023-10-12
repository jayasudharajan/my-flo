-- see info:
SELECT * FROM timescaledb_information.continuous_aggregates;

-- set compute stop at -33 days
alter view water_hourly set (timescaledb.ignore_invalidation_older_than = '33 days');

-- count rows for all hyper tables
SELECT h.schema_name,
       h.table_name,
       h.id AS table_id,
       h.associated_table_prefix,
       row_estimate.row_estimate
FROM _timescaledb_catalog.hypertable h
         CROSS JOIN LATERAL ( SELECT sum(cl.reltuples) AS row_estimate
                              FROM _timescaledb_catalog.chunk c
                                       JOIN pg_class cl ON cl.relname = c.table_name
                              WHERE c.hypertable_id = h.id
                              GROUP BY h.schema_name, h.table_name) row_estimate
ORDER BY schema_name, table_name;

-- query for the earliest rows of 5mnin table, order is already asc
select bk,device_id from water_5min limit 10;
-- get count for days less than 2020-2-29
select count(bk) from water_5min where bk < '2020-02-29';

-- query for earliest rows & count of hourly table
\d+ water_hourly;
-- grab the hypertable name, should be: _timescaledb_internal._materialized_hypertable_xxx then query with it as if we were doing it for the view
select device_id,bucket from _timescaledb_internal._materialized_hypertable_10 order by bucket asc limit 10;
select count(bucket) from _timescaledb_internal._materialized_hypertable_10 where bucket < '2020-02-29';

/*
select device_id,bucket from _timescaledb_internal._materialized_hypertable_217 order by bucket asc limit 10;
+-------------------+---------------------+
| device_id         | bucket              |
|-------------------+---------------------|
| 04:ad:ef:a3:6d:64 | 2020-02-28 17:00:00 |
| 5b:1a:84:b6:27:c4 | 2020-02-28 17:00:00 |
| 79:d3:fb:15:d7:44 | 2020-02-28 17:00:00 |
| de:cb:ec:ba:40:74 | 2020-02-28 17:00:00 |
| 04:ad:ef:a3:6d:64 | 2020-02-29 01:00:00 |
| 79:d3:fb:15:d7:44 | 2020-02-29 01:00:00 |
| de:cb:ec:ba:40:74 | 2020-02-29 01:00:00 |
| 3f:55:ce:f0:a6:c4 | 2020-03-02 10:00:00 |
| 3f:55:ce:f0:a6:c4 | 2020-03-02 11:00:00 |
| 4f:d9:4e:85:f4:84 | 2020-03-02 11:00:00 |
+-------------------+---------------------+
select count(bucket) from _timescaledb_internal._materialized_hypertable_217 where bucket < '2020-02-29';
+---------+
| count   |
|---------|
| 4       |
+---------+
 */

-- NOW test DELETE up to 2020-02-29 (today is 3-4)
SELECT drop_chunks(timestamp '2020-03-15T00:00:00', 'water_5min', cascade => true, cascade_to_materializations => false);
-- check 5mni data to see its removed
select bk,device_id from water_5min limit 10;
select count(bk) from water_5min where bk < '2020-03-15';
-- force update
REFRESH MATERIALIZED VIEW water_hourly;
-- check hourly data to ensure it's still there
select device_id,bucket from _timescaledb_internal._materialized_hypertable_10 order by bucket asc limit 10;
select count(bucket) from _timescaledb_internal._materialized_hypertable_10 where bucket < '2020-02-29';

-- drop chunk policy
SELECT drop_chunks(interval '33 day', 'water_5min', cascade => true, cascade_to_materializations => false);
SELECT add_drop_chunks_policy('water_5min', interval '34 day', cascade => true, if_not_exists => true, cascade_to_materializations => false);
-- check added policies
select * from timescaledb_information.policy_stats;

/*
-- NOTE: don't do this for aggregation table
-- compress chunks
ALTER TABLE archive_water_hourly SET (timescaledb.compress, timescaledb.compress_orderby = 'did, time DESC', timescaledb.compress_segmentby = '');
SELECT add_compress_chunks_policy('archive_water_hourly', INTERVAL '35 day');
-- check added policies
select * from timescaledb_information.policy_stats;

-- decompress all chunks as roll back
SELECT decompress_chunk(i) from show_chunks('archive_water_hourly') i;
SELECT remove_compress_chunks_policy('archive_water_hourly');
*/