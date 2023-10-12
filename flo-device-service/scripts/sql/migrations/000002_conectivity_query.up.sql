BEGIN;
    ALTER TABLE devices ADD column mobile_connectivity bool;
   
    CREATE index on devices (mobile_connectivity);
    COMMIT;
END;
