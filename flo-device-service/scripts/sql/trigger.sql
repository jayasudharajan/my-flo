CREATE OR REPLACE FUNCTION set_created_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_time = now() at time zone 'utc';
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_devices_created_column BEFORE INSERT ON devices FOR EACH ROW EXECUTE PROCEDURE set_created_column();

CREATE TRIGGER set_telemetry_created_column BEFORE INSERT ON telemetry FOR EACH ROW EXECUTE PROCEDURE set_created_column();
