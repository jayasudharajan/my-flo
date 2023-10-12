BEGIN;
    ALTER TABLE global_device_config ADD column provisioning JSON;
    CREATE TABLE IF NOT EXISTS task (
            id varchar not null,
            mac_address varchar,
            task_type varchar not null,
            task_state smallint default 0 not null,
            created_at timestamp default now() not null,
            updated_at timestamp default now() not null,
            primary key(id)
    );

    CREATE index on task (task_type, created_at);
  
    DELETE FROM global_device_config WHERE key = 'firmwareProperties.telemetry_batched_interval';
    
    INSERT INTO global_device_config (make, model, "key", value,provisioning) VALUES
    ('flo_device_v2', 'flo_device_075_v2', 'firmwareProperties.telemetry_batched_interval', 
        '600', '{"onPairing":{"enabled": false}}');

    INSERT INTO global_device_config (make, model, "key", value,provisioning) VALUES
    ('flo_device_v2', 'flo_device_100_v2', 'firmwareProperties.telemetry_batched_interval', 
        '600', '{"onPairing":{"enabled": false}}');

    INSERT INTO global_device_config (make, model, "key", value,provisioning) VALUES
    ('flo_device_v2', 'flo_device_125_v2', 'firmwareProperties.telemetry_batched_interval', 
        '600', '{"onPairing":{"enabled": false}}');

    COMMIT;
END;
