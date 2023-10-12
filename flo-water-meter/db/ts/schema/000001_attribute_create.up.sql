BEGIN;
    CREATE TABLE IF NOT EXISTS water_meter_attr (
            attr_id varchar not null,
            attr_val varchar,
            updated_at timestamp default now() not null,
            primary key(attr_id)
    );

    INSERT INTO water_meter_attr (attr_id, attr_val) VALUES ('archive_start_date', '2017-03-02T00:00:00');
    INSERT INTO water_meter_attr (attr_id, attr_val) VALUES ('archive_end_date', '2020-03-01T00:00:00');
    INSERT INTO water_meter_attr (attr_id, attr_val) VALUES ('live_data_start_date', '2020-03-01T00:00:00');

    COMMIT;
END;
