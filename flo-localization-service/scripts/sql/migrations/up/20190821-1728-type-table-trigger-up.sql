CREATE OR REPLACE FUNCTION set_created_column()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.created = now() at time zone 'utc';
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_types_created_column BEFORE INSERT ON types FOR EACH ROW EXECUTE PROCEDURE set_created_column();