# Smart Aid Application Security Review (V1 Edition)

**Review Date:** 2026-10-17  
**Scope:** Spring Security Architecture, JWT & Refresh Token Lifecycle, PostGIS & PostgreSQL Data Isolation, RBAC Authorization Boundaries, Concurrency Controls, Idempotency, and STOMP Channel Security.  
**Classification:** Internal Technical Audit & Hardening Report

---

## 1. Security Architecture & Controls Overview

| Security Domain | Implemented Control | Live Verification Evidence |
| :--- | :--- | :--- |
| **Credential Storage** | `BCryptPasswordEncoder` (strength 10). Plaintext passwords are never persisted. | **VERIFIED:** Passwords stored only as salted BCrypt hashes in PostgreSQL `users` table. Tested live via registration & authentication flow. |
| **Access Tokens** | Short-lived signed HMAC-SHA256 JWT containing user UUID and role claims (`ROLE_CITIZEN`, `ROLE_VOLUNTEER`, `ROLE_EMS`, `ROLE_ADMIN`). | **VERIFIED:** Validated by `JwtAuthFilter` on each HTTP request. Invalid, forged, or expired tokens immediately return HTTP 401 Unauthorized. |
| **Refresh Tokens** | Cryptographically secure 48-byte random strings. Database persists only the SHA-256 hash. Rotation is enforced on every refresh call; old token is revoked. | **VERIFIED:** Live refresh rotation validated in E2E stage 3 (`refresh-rotation`). Re-using an old token is rejected. |
| **Role-Based Authorization (RBAC)** | Spring Method Security (`@PreAuthorize`) and route-level URL patterns. Roles are never trusted from client input. | **VERIFIED:** Live checks in `test-end-to-end.ps1` confirm Citizen cannot access EMS endpoints (HTTP 403 Forbidden), and unauthenticated access returns HTTP 401. |
| **Resource Ownership & Privacy** | Incident retrieval, medical profile access, emergency contacts, and notifications enforce owner ID matching in SQL queries. | **VERIFIED:** Tested in E2E stage 6 (`contacts-crud`) and stage 5 (`medical-profile`). Users cannot view or modify other users' medical or contact records. |
| **SOS Duplicate Protection** | `Idempotency-Key` header with PostgreSQL advisory locking (`pg_advisory_xact_lock`) and canonical SHA-256 request fingerprinting. | **VERIFIED:** Network retries with identical idempotency keys return the existing incident without duplicate DB insertions. Tested in `IncidentRequestFingerprintTest`. |
| **Emergency Concurrency Safety** | Pessimistic database row locks (`SELECT ... FOR UPDATE`) on incidents during volunteer assignment and status updates. Unique database constraints prevent multiple responders on a single case. | **VERIFIED:** Volunteer mission acceptance enforces strict concurrency safety. Verified in E2E stage 9. |
| **WebSocket / STOMP Security** | `StompAuthChannelInterceptor` intercepts `CONNECT` frames, validates JWT bearer tokens, and verifies topic subscriptions against user authorization. | **VERIFIED:** Live STOMP handshake over `/ws` and subscription to `/topic/incidents/{id}` verified in E2E stage 10. |
| **Auth Abuse Protection** | `AuthRateLimitFilter` with sliding-window limiter on `/api/auth/**` to prevent brute-force attacks. | **VERIFIED:** Passed unit tests in `AuthRateLimitFilterTest`. |
| **Client-Side Secret Isolation** | Tokens stored in hardware-backed secure storage via `flutter_secure_storage` (Keystore on Android, Keychain on iOS). No credentials in plaintext `SharedPreferences`. | **VERIFIED:** Inspected in `TokenStore.dart` and mobile integration. |

---

## 2. Specific Attack Vectors Mitigated

### 2.1 Replay Attacks & Network Retries
- **Vulnerability:** Under poor cellular emergency conditions, a citizen's mobile client re-transmits an SOS payload after an HTTP timeout, creating multiple active emergency incidents.
- **Mitigation:** The client generates a UUID `Idempotency-Key` before transmission and reuses it on retry. The backend acquires a transaction advisory lock on the key, checks `incident_idempotency_keys`, and returns the existing incident if fingerprints match, returning HTTP 409 Conflict if payload changed.

### 2.2 Unauthorized Incident Cancellation
- **Vulnerability:** A citizen panics or accidentally cancels an incident after volunteer responders or ambulances have already been dispatched.
- **Mitigation:** Server-side state transition rule in `IncidentStatus.canBeCancelledByReporter()` restricts reporter cancellation to `NEW` and `SEARCHING` states. Once in `RESPONDER_ASSIGNED`, `EMS_ASSIGNED`, or later states, cancellation requires coordinator authority (`ROLE_EMS` or `ROLE_ADMIN`).

### 2.3 Privilege Escalation via Mass Assignment
- **Vulnerability:** A user registers as a volunteer or citizen and submits an administrative role in the JSON payload.
- **Mitigation:** `AuthService.register()` explicitly ignores incoming role attributes and assigns fixed roles based on the requested account type (`ROLE_CITIZEN`, `ROLE_VOLUNTEER`). Administrative and EMS credentials cannot be created via public registration.

---

## 3. Operational Security Guidelines for Production Deployment

1. **Production Reverse Proxy & TLS:** Deploy behind an NGINX or Cloudflare reverse proxy with TLS 1.3, HSTS (`Strict-Transport-Security: max-age=31536000; includeSubDomains`), and restrictive Content-Security-Policy (CSP) headers.
2. **Environment Secret Management:** Never commit secrets to source control. In production, inject `JWT_SECRET`, `DB_PASSWORD`, and API keys via cloud secret managers (e.g. AWS Secrets Manager, HashiCorp Vault, or Google Secret Manager).
3. **Push Notification Privacy:** In-flight push notification payloads via FCM or APNs must omit sensitive medical data (e.g., blood types or allergy details) and only convey event notification alerts (`"New incident in your area"`). Sensitive data is retrieved only after an authenticated client fetch over TLS.
