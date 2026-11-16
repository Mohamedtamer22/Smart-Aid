-- Run natively with PostgreSQL/pgAdmin as a PostgreSQL administrator.
-- Change the password before use; do not add real credentials to source control.
`CREATE ROLE smartaid_user WITH LOGIN PASSWORD 'replace-with-a-long-unique-database-password';
CREATE DATABASE smartaid OWNER smartaid_user;
\\connect smartaid
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
GRANT ALL ON SCHEMA public TO smartaid_user;
`