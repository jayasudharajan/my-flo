CREATE OR REPLACE FUNCTION set_created_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created = now() at time zone 'utc';
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_assets_created_column BEFORE INSERT ON assets FOR EACH ROW EXECUTE PROCEDURE set_created_column();

CREATE TRIGGER set_tags_created_column BEFORE INSERT ON tags FOR EACH ROW EXECUTE PROCEDURE set_created_column();
