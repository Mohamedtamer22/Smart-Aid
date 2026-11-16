# Native deployment

This is a one-machine development deployment. Install PostgreSQL with PostGIS natively, create the role/database with `database/bootstrap.sql`, set `.env`, run Flyway by starting Spring Boot, and run Flutter from the same host. Java/Maven/Flutter checks and a PostgreSQL 18 + PostGIS/Flyway local integration smoke test succeeded on 2026-10-03. `psql` need not be on `PATH` when using pgAdmin or PostgreSQL's full executable path.

For HTTPS-ready local testing, place a native reverse proxy or application TLS configuration in front of `localhost:8080` and configure CORS explicitly. That future setup must remain native; this repository intentionally provides no container manifests, build files, or scripts.
