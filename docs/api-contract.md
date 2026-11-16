# API contract

All routes return JSON. Controllers use request/response DTOs; JPA entities are never serialized. Errors follow:

```json
{"timestamp":"2026-09-26T00:00:00Z","status":403,"code":"ACCESS_DENIED","message":"You are not allowed to perform this action","path":"/api/...","traceId":"..."}
```

| Route | Access | Request / response | Status |
| --- | --- | --- | --- |
| `POST /api/auth/register` | Public, locally rate limited | `email`, `displayName`, 12+ char `password` → tokens + user | Implemented |
| `POST /api/auth/login` | Public, locally rate limited | `email`, `password` → tokens + user | Implemented |
| `POST /api/auth/refresh` | Public | opaque refresh token → rotated token pair | Implemented |
| `POST /api/auth/logout` | Public | opaque refresh token → 204 | Implemented |
| `POST /api/incidents` | Valid JWT | manual emergency type, coordinates, optional structured triage → `201` incident | Implemented |
| `GET /api/incidents/mine` | Valid JWT | current reporter’s incidents | Implemented |
| `GET /api/incidents/{id}` | reporter, EMS/Admin | incident and immutable status timeline | Implemented |
| `PATCH /api/incidents/{id}/status` | owner may cancel; EMS/Admin coordinates | validated status/reason → incident | Implemented |
| `GET /api/users/me` | Valid JWT | server-derived display identity and roles | Implemented |
| `GET` / `PUT /api/medical-profile` | Valid JWT, own profile only | user-controlled emergency profile; access/update is audited | Implemented |
| `GET` / `POST /api/emergency-contacts` | Valid JWT, own contacts only | list/create emergency contacts | Implemented |
| `PUT` / `DELETE /api/emergency-contacts/{id}` | Valid JWT, owning contact only | update/delete an emergency contact | Implemented |
| `GET /api/notifications` | Valid JWT, own notifications only | latest 100 notification metadata records | Implemented |
| `PATCH /api/notifications/{id}/read` | Valid JWT, owning notification only | mark an owned notification read | Implemented |
| `GET /api/smart-dispatch/incidents/{id}/recommendations` | EMS/Admin | verified, available, certified responder ranking | Implemented, data dependent |
| `GET /api/smart-er/incidents/{id}/recommendations` | EMS/Admin | verified hospital decision-support ranking | Implemented, data dependent |
| `POST /api/volunteers/me/onboarding` | Any authenticated user | creates an unverified, unavailable volunteer profile; never grants a role | Implemented |
| `GET /api/volunteers/me` | VOLUNTEER | readiness, credentials and permitted location state | Implemented |
| `PUT /api/volunteers/me/availability` | VOLUNTEER | `available` boolean → readiness; cannot opt out during an active mission | Implemented |
| `PUT /api/volunteers/me/location` | VOLUNTEER | validated latitude/longitude → readiness | Implemented |
| `GET /api/volunteers/dashboard` | VOLUNTEER | readiness, active mission, eligible-nearby count | Implemented |
| `GET /api/volunteers/incidents/nearby` | VOLUNTEER | eligible searching incidents within configured radius | Implemented |
| `POST /api/volunteers/incidents/{id}/accept` | VOLUNTEER | atomically creates the single responder assignment and returns a mission | Implemented |
| `GET /api/volunteers/missions/active` | VOLUNTEER | current accepted/arrived mission | Implemented |
| `PATCH /api/volunteers/missions/{id}` | owning VOLUNTEER | `ARRIVED` or `COMPLETED` according to valid mission state | Implemented |
| `GET /api/ems/dashboard` | EMS/Admin | active/critical counts and non-terminal incident summaries | Implemented |
| `GET /api/ems/incidents/{id}` | EMS/Admin | incident summary, notes, and status timeline | Implemented |
| `POST /api/ems/incidents/{id}/assign` | EMS/Admin | starts EMS coordination from a permitted incident state | Implemented |

Volunteers may only see an incident after the server confirms verified profile, active availability, valid certification, current location, radius, and required skills. An acceptance locks the incident and accepts at most one volunteer; a client retry cannot win a second assignment. Profile onboarding never self-verifies, self-certifies, or grants `VOLUNTEER`.

OpenAPI describes the live controller signatures at `/v3/api-docs` and interactive Swagger UI at `/swagger-ui/index.html`. Ambulance, AED, training, analytics, and admin CRUD endpoints are still planned; their tables alone do not imply an endpoint exists.
