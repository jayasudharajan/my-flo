BEGIN;
    
    CREATE INDEX concurrently idx_puck_telemetry_created_time  on puck_telemetry (created_time asc);
    COMMIT;
END;
