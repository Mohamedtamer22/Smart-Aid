# Security

Passwords are BCrypt hashes; plaintext passwords, tokens, secrets, and medical fields are not logged. Registration always grants only `USER`; roles in a Flutter request are ignored. Short-lived HMAC-signed JWT access tokens carry verified server roles, while opaque 48-byte refresh values are SHA-256 hashed in PostgreSQL and rotated/revoked on use.

Spring Security is stateless, validates input, sends restrictive headers, permits an explicit CORS allow-list, returns safe structured errors, and records authentication/incident transitions in audit logs with a trace ID. An in-memory guard allows 10 authentication attempts/minute per client address, endpoint, and submitted email; it prevents repeated guessing without locking distinct local demo accounts that share one machine. Production needs a shared, proxy-aware limiter and an abuse review. EMS/Admin authorization is enforced on dispatch and Smart ER routes. Medical profile and emergency-contact routes require the authenticated owner; sensitive-data access requires further production review.

STOMP connect frames must carry `Authorization: Bearer <token>`. A user may subscribe only to their own `/topic/incidents/{id}`; EMS/Admin may subscribe to operational incidents. Production deployment must terminate HTTPS/WSS upstream, restrict CORS to known origins, add a shared rate-limit store, rotate JWT keys, protect database backups, and conduct a threat model before real use.

The current in-process broker and development auth throttling are not a production scale design. No real emergency dispatch integration, clinical record integration, or push provider is enabled.
