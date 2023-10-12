-- NOTE: this doesn't work for prod large data set
-- SELECT remove_continuous_aggregate_policy('water_hourly');

select delete_job(job_id) from timescaledb_information.jobs where proc_name='refresh_water_hourly';
-- select * from timescaledb_information.jobs;