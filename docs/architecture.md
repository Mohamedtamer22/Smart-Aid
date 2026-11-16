# Architecture

Smart Aid is a native local modular monolith:

```text
Flutter mobile client
  HTTPS-ready REST + STOMP/WebSocket
Spring Boot API (localhost:8080)
  security | incident workflow | dispatch | Smart ER | notifications
PostgreSQL + PostGIS (localhost:5432)
```

The Flutter client stores only encrypted session tokens. It uses the API for all domain data. Spring Security derives identity and roles from a verified access token; client-provided roles are ignored. PostgreSQL/PostGIS is the system of record, and Flyway owns schema changes.

The backend is intentionally modular by package/domain, not a distributed system: `auth`, `incident`, `volunteer`, `smarter`, `notification`, `audit`, and shared `config/security/exception`. It can evolve without premature infrastructure. External maps, push, or AI are optional adapters behind interfaces and are disabled unless configured.

`MANUAL` emergency creation is the only implemented detection source. Wearable, crash, and sensor source types are modeled as future integrations; no smartphone-only automatic medical detection is claimed.
