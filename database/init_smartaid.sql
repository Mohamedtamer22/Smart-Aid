DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'smartaid_user') THEN
    CREATE ROLE smartaid_user WITH LOGIN PASSWORD 'smartaid-local-only-rotate-before-production-91!';
  ELSE
    ALTER ROLE smartaid_user WITH LOGIN PASSWORD 'smartaid-local-only-rotate-before-production-91!';
  END IF;
END $$;

SELECT 'CREATE DATABASE smartaid OWNER smartaid_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'smartaid')\gexec

\connect smartaid
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
GRANT ALL ON SCHEMA public TO smartaid_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO smartaid_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO smartaid_user;
