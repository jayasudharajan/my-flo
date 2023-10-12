-- NOTE: 1 billion bytes == 1 giga byte
-- SELECT * FROM hypertable_detailed_size('water_5min') ORDER BY node_name;
-- SEE: https://docs.timescale.com/timescaledb/latest/how-to-guides/data-retention/create-a-retention-policy/
-- SELECT remove_retention_policy('water_hourly');
SELECT add_retention_policy('water_hourly', INTERVAL '2 months');
-- select * from timescaledb_information.jobs;
-- SELECT * FROM timescaledb_information.job_stats;

-- SELECT remove_retention_policy('water_5min');
SELECT add_retention_policy('water_5min', INTERVAL '3 months');
-- SELECT * FROM hypertable_detailed_size('water_5min') ORDER BY node_name;