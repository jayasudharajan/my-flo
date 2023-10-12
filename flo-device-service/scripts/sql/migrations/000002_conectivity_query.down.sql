BEGIN;
    ALTER TABLE devices DROP column mobile_connectivity;
    COMMIT;
END;
