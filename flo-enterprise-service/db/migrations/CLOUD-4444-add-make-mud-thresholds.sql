do $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='mud_threshold_defaults'  and column_name='make') THEN

    alter table mud_threshold_defaults add column make varchar;

    update mud_threshold_defaults set make = 'flo_device_v2';

    insert into mud_threshold_defaults (account_id, make, threshold_values_json, start_minute, end_minute, order, repeat_json, created_at, updated_at)
    values (null, 'puck_oem', '{"minTempF": 25, "maxTempF": 95, "maxHumidity": 70, "minHumidity": 15, "minBattery": 10}', 0, 0, 0, '{}', current_timestamp, current_timestamp)

    END IF;
END;
$$