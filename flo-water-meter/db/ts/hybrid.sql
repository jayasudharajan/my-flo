-- DROP TABLE IF EXISTS "water_5min" CASCADE;
CREATE TABLE IF NOT EXISTS "water_5min" (
  bk TIMESTAMP NOT NULL, -- bk: time stamp in UTC, will floor to the nearest 5min bucket. We can use TS time_bucket(...)
  device_id MACADDR NOT NULL, -- device_id: should be in mac address (native to pg at 6 bytes!) SEE: https://www.postgresql.org/docs/9.4/datatype-net-types.html#DATATYPE-MACADDR

  seconds SMALLINT NOT NULL, -- seconds: how many 1s entries is rolled up in this
  seconds_flo SMALLINT NOT NULL,  -- seconds_flo: how  many 1s entries for flowing water (ie: gpm > 0)  
  seconds_slot BIT(300) NOT NULL, -- seconds_slot: a bit for each of the 300 seconds in this span of time. 1 == filled, 0 == missing
  
  total_gallon REAL NOT NULL, -- total_gallon: computed total water usage witn the 5min span in gallon
  
  gpm_sum REAL NULL, -- gpm_sum: sum of all 1s gpm averages
  gpm_min_flo REAL NULL, -- gpm_min_flo: min gpm for this 5min block if there is flowing water (or else the min might just be 0 always as it only takes 1s of no water in the 5min block to be 0)
  gpm_max REAL NULL, -- gpm_max: max gpm for this 5min block
  
  psi_sum REAL NULL, -- psi_sum: sum of all 1s psi averages
  psi_min REAL NULL, -- psi_min: min psi for this 5min block
  psi_max REAL NULL, -- psi_max: max psi for this 5min block
  
  temp_sum REAL NULL, -- temp_sum: the sum of all added 1s temperature averages
  temp_min REAL NULL, -- temp_min: min temp within this 5min block
  temp_max REAL NULL -- temp_max: max temp within this 5min block
);
/*
NOTE: table is a 5 minute pre-aggregate block of water data per device
SEE: https://www.percona.com/blog/2019/07/16/brin-index-for-postgresql-dont-forget-the-benefits/
    https://info.crunchydata.com/blog/postgresql-brin-indexes-big-data-performance-with-minimal-storage
    We are using BRIN index for larger, sequential & clustered data for our 5min usage table
*/
-- -- Largest IX & main use for apps, should be UNIQUE but is only supported for BTREE & not BRIN
CREATE UNIQUE INDEX IF NOT EXISTS "water_5min_did_bk_idx" ON "water_5min" USING BTREE (device_id, bk DESC);
-- maybe not needed outside of adhoc query?!
-- -- Second largest IX: bucket only, used mainly for pre-caching services
CREATE INDEX IF NOT EXISTS "water_5min_bk_brin2" ON "water_5min" USING BRIN (bk) WITH (timescaledb.transaction_per_chunk);

/*
NOTE: HT hot shards SHOULD fit into ram for good performance.  Ensuring that it does not exceed 25% of VM RAM is a good rule. 
    Planning for the future of 10X at similar performance, current settings peg that as the goal so we don't need to change this at 10X
SEE: https://docs.timescale.com/latest/using-timescaledb/hypertables#best-practices
*/
SELECT
  create_hypertable(
    'water_5min',
    'bk',
    chunk_time_interval => interval '3d'
  );

-- DEF: Auto roll-ups of the 5min buckets to hourly buckets using TS
-- DROP VIEW IF EXISTS "water_hourly" CASCADE;
CREATE VIEW "water_hourly" WITH (
  timescaledb.continuous,
  timescaledb.refresh_lag = '0s',
  timescaledb.refresh_interval = '5m',
  timescaledb.ignore_invalidation_older_than = '31d'
) AS SELECT
  device_id,
  time_bucket('1h', bk) as bucket,
  cast(sum(seconds) as int) as seconds,
  cast(sum(seconds_flo) as int) as seconds_flo,
  sum(total_gallon) as total_gallon,

  CASE
    WHEN sum(seconds_flo) = 0 THEN 0
    ELSE cast(sum(gpm_sum) / sum(seconds_flo) as real)
  END AS gpm_avg,

  COALESCE(min(NULLIF(gpm_min_flo, 0)), 0) AS gpm_min_flo,
  max(gpm_max) AS gpm_max,

  CASE
    WHEN sum(seconds) = 0 THEN 0
    ELSE cast(sum(psi_sum) / sum(seconds) as real)
  END AS psi_avg,

  min(psi_min) AS psi_min,
  max(psi_max) AS psi_max,

  CASE
    WHEN sum(seconds) = 0 THEN 0
    ELSE cast(sum(temp_sum) / sum(seconds) as real)
  END as temp_avg,

  min(temp_min) AS temp_min,
  max(temp_max) AS temp_max
FROM water_5min
GROUP BY
  device_id, bucket;

-- REFRESH MATERIALIZED VIEW water_hourly;
-- psql postgres://x.y.z < hybrid.sql
-- ALTER VIEW water_hourly SET (timescaledb.refresh_lag = '0s', timescaledb.refresh_interval = '5m');
-- SELECT set_chunk_time_interval('water_5min', interval '3d');
-- SELECT add_drop_chunks_policy('water_5min', INTERVAL '14 months', cascade_to_materializations => false);

-- select * from timescaledb_information.continuous_aggregates;
-- select * from timescaledb_information.continuous_aggregate_stats;
-- SELECT view_name, refresh_lag, refresh_interval, max_interval_per_job, ignore_invalidation_older_than, materialization_hypertable FROM timescaledb_information.continuous_aggregates;

-- ALTER VIEW water_hourly SET (timescaledb.ignore_invalidation_older_than = '31d');
-- ALTER VIEW water_hourly SET (timescaledb.max_interval_per_job = '3h');
-- REFRESH MATERIALIZED VIEW water_hourly;

/*
alter table telemetry_hourly alter column did type MACADDR using did::MACADDR;

alter table telemetry_hourly 
  alter column average_flowrate type real,
  alter column average_pressure type real,
  alter column average_temperature type real,
  alter column total_flow type real;

alter table telemetry_hourly rename to archive_water_hourly; 
CREATE INDEX IF NOT EXISTS "archive_hourly_time_brin" ON "archive_water_hourly" USING BRIN (time) WITH (timescaledb.transaction_per_chunk);
CREATE INDEX IF NOT EXISTS "archive_hourly_did_time_idx" ON "archive_water_hourly" USING BTREE (did, time) WITH (timescaledb.transaction_per_chunk);
*/