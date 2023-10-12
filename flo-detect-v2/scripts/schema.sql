-- Role: flo_service_role
-- DROP ROLE flo_service_role;

CREATE ROLE flo_service_role WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

GRANT flo_service_role TO master WITH ADMIN OPTION;

-- Database: flo-detect
-- DROP DATABASE "flo-detect";

CREATE DATABASE "flo-detect"
    WITH
    OWNER = flo_service_role
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    CONNECTION LIMIT = -1;

-- Role: "flo-detect"
-- DROP ROLE "flo-detect";

CREATE ROLE "flo-detect" WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

GRANT flo_service_role TO "flo-detect" WITH ADMIN OPTION;
