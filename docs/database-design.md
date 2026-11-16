# Database design

Flyway migration `V1__initial_schema.sql` creates UUID-keyed normalized tables for identities/roles, refresh tokens, medical data, incidents and immutable status history, volunteer credentials, hospital capabilities/resources, ambulance tracking, emergency responses, AED resources, notifications, training, audit logs, and settings.

`V3__volunteer_response_workflow.sql` adds mission arrival/update timestamps, a constrained volunteer mission status (`ACCEPTED`, `ARRIVED`, `COMPLETED`, `CANCELLED`), and a unique incident response. The unique constraint is the database backstop for the one-volunteer acceptance decision; the application also locks the incident before creating the response.

Latitude/longitude inputs are constrained to valid ranges. Database triggers derive PostGIS `geography(Point,4326)` columns, and GIST indexes support nearby incident, hospital, ambulance, and AED search. JPA DTOs expose coordinates, never persistence entities.

PostGIS and `pgcrypto` extensions must be enabled by a locally privileged database owner before migration. The schema contains no real hospital, AED, or patient seed data; operational data must be verified by its accountable source.
