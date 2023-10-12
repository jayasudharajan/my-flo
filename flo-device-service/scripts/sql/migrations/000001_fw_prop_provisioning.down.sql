BEGIN;
    DELETE FROM global_device_config WHERE key = 'firmwareProperties.telemetry_batched_interval';
    ALTER TABLE global_device_config DROP column provisioning ;
    DROP TABLE IF EXISTS task cascade;
    COMMIT;
END;
