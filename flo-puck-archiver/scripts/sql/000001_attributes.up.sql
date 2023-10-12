BEGIN;
    CREATE TABLE IF NOT EXISTS puck_attribute (
            attr_id varchar not null,
            attr_val varchar,
            updated_at timestamp default now() not null,
            primary key(attr_id)
    );

    INSERT INTO puck_attribute (attr_id, attr_val) VALUES ('telemetry_archive_end_date', '2018-01-01T00:00:00');
    INSERT INTO puck_attribute (attr_id, attr_val) VALUES ('telemetry_archive_device_hint', '000000000000')

    COMMIT;
END;
