-- NOTE: this doesn't work for prod large data set
-- SELECT add_continuous_aggregate_policy('water_hourly', start_offset => '3 h', end_offset => '1 h', schedule_interval => '1 h');

-- WARNING: not needed any longer, we're doing this in code!
/*
create OR REPLACE procedure refresh_water_hourly(job_id integer, config jsonb)
    language plpgsql
as
$$
DECLARE
    run_ts timestamp := now();
    cur_ts timestamp := time_bucket('1hour ', run_ts);
    start_ts timestamp:= cur_ts + (config->>'start_offset')::interval;
    end_ts timestamp:= cur_ts + (config->>'end_offset')::interval;
    bk_size interval:= (config->>'max_interval_per_job')::interval;
    counter integer:=0;
BEGIN
    RAISE INFO 'refresh_water_hourly(#% "%" -> "%" | "%") START %', job_id, start_ts, end_ts, bk_size, run_ts;
    cur_ts := start_ts;
    loop
        RAISE DEBUG 'Cur % - To %', cur_ts, cur_ts + bk_size;
        -- CALL refresh_continuous_aggregate('water_hourly', cur_ts::timestamp without time zone, (cur_ts + bk_size)::timestamp without time zone);
        -- execute format('CALL refresh_continuous_aggregate(''water_hourly'', ''%s''::timestamp without time zone, ''%s''::timestamp without time zone);', cur_ts, cur_ts + bk_size);

        counter := counter + 1;
        cur_ts := cur_ts + bk_size;
        exit when cur_ts >= end_ts;
    end loop;
    RAISE NOTICE 'refresh_water_hourly(#% "%" -> "%" | "%") DONE % | TOOK % | PROCESSED %', job_id, start_ts, end_ts, bk_size, now(), now()-run_ts, counter;
END
$$;

alter procedure refresh_water_hourly(integer, jsonb) owner to tsdbadmin;

SELECT add_job('refresh_water_hourly','15 minutes', config => '{"end_offset": "-1 hour", "start_offset": "-24 hours", "max_interval_per_job": "1 hour"}');
*/

-- select * from timescaledb_information.jobs;
-- select * from timescaledb_information.jobs where proc_name='refresh_water_hourly';
-- SELECT * FROM timescaledb_information.job_stats;

-- NOTE: to debug the func
-- SET client_min_messages TO DEBUG1;
-- call refresh_water_hourly(1272, '{"end_offset": "-1 hour", "start_offset": "-24 hours", "max_interval_per_job": "1 hour"}');
/*
call refresh_continuous_aggregate('water_hourly',
    (DATE_TRUNC('hour', now()) - interval '1 h')::timestamp without time zone,
    DATE_TRUNC('hour', now())::timestamp without time zone);
 */