# Smart Aid — Security, Privacy & Medical Safety Audit

**Project:** Smart Aid  
**Team:** FirstLine  
**Audit Date:** 2026-11-16  
**Auditor:** Information Security & Clinical Safety Systems Auditor  
**Audit Scope:** Full-stack security controls, medical data privacy, clinical safety boundaries, and risk register.

---

## 1. Medical Safety Boundaries & Clinical Disclaimers

Smart Aid operates at the critical intersection of telecommunications, geospatial logistics, and emergency healthcare. To safeguard patient welfare and comply with medical device regulatory boundaries, the system is engineered under strict clinical guardrails:

### 1.1 Core Safety Principles
1. **Decision Support, Not Autonomous Diagnosis:**
   - Smart Aid does not provide automated diagnostic conclusions or clinical medical treatments.
   - In `TriageService.java`, the system evaluates structured emergency indicators (e.g., breathing, consciousness, bleeding) to suggest a dispatch priority (`CRITICAL`, `HIGH`, `STANDARD`).
   - Every generated triage record appends an explicit warning: *"This is structured decision support, not a diagnosis."*
2. **Human-in-the-Loop Clinical Authority:**
   - All critical operational actions—such as ambulance dispatch, hospital destination confirmation, and volunteer task assignment—require conscious human authorization by an EMS coordinator, triage officer, or medical director.
   - The Smart ER algorithm recommends optimal destinations based on logistical and capability criteria, but EMS personnel can override algorithmic suggestions at any time via the ECC interface.
3. **Emergency Service Non-Replacement:**
   - The application explicitly informs users in onboarding and emergency dialogs that Smart Aid is an auxiliary coordination tool and **does not replace national emergency dispatch hotlines (e.g., 123 in Egypt or 911 internationally)**.
4. **Prescription & Medicine Delivery Restrictions:**
   - The platform strictly avoids automated medication prescribing. Any future pharmacy module must require verified physician prescription authorization and licensed pharmacist dispensing.

---

## 2. Information Security Architecture & Privacy Safeguards

### 2.1 Authentication & Credential Protection
- **Password Security:** User passwords are encrypted using **BCrypt** with adaptive workload factor (`AuthService.java`). Raw passwords are never logged, cached, or transmitted to client devices.
- **Short-Lived Access Tokens:** Authentication is maintained via JSON Web Tokens (JWT) signed with HMAC-SHA256 (`JwtService.java`) with a strictly enforced **15-minute expiration window**.
- **Cryptographic Refresh Token Rotation:**
  - Refresh tokens (14-day validity) are never stored in plaintext. They are hashed using **SHA-256** prior to database persistence in the `refresh_tokens` table.
  - Upon use (`POST /api/auth/refresh`), the presented token is immediately revoked, and a brand-new token pair is issued.
  - If a previously consumed or revoked refresh token is presented, the server detects token replay and immediately revokes all active refresh tokens for that user account.
- **Brute-Force & Denial-of-Service Defense:**
  - `AuthRateLimitFilter.java` intercepts all requests to `/api/auth/**`.
  - Enforces an in-memory sliding window rate limit of 10 requests per minute per IP address, responding with `429 Too Many Requests` on violation.

### 2.2 Server-Side Authorization & Multi-Tenancy Scoping
- **Role-Based Access Control (RBAC):**
  - Enforced via Spring Security `@PreAuthorize` method annotations across all controller endpoints:
    - `ROLE_USER`: Standard citizen access (own emergencies, own profile).
    - `ROLE_VOLUNTEER`: Nearby incident radar, mission acceptance, mission status updates.
    - `ROLE_EMS`: Emergency queue, dispatch management, Smart ER hospital ranking.
    - `ROLE_ADMIN`: User management, credential verification, immutable audit log inspection.
    - `ROLE_HOSPITAL`: Pending partner status verification.
- **Tenant Data Isolation:**
  - Endpoints such as `/api/incidents/mine`, `/api/medical-profile`, and `/api/emergency-contacts` strictly filter records by the authenticated caller's principal UUID (`(UUID) authentication.getPrincipal()`).
  - Cross-user data harvesting attempts return `403 Forbidden` or `404 Not Found`.

### 2.3 Patient Medical ID Privacy & Consent Controls
- **Explicit Consent Toggle (`sharing_consent`):**
  - In `medical_profiles`, the patient controls a boolean `sharing_consent` flag.
  - The patient's blood type, allergies, and current medications are accessible to authorized EMS personnel only during an active, unresolved emergency involving that specific patient.
- **Tamper-Evident Security Audit Trail:**
  - The `audit_logs` table records an immutable event log for every sensitive data access or mutation:
    - `MEDICAL_PROFILE_ACCESSED`: Logged whenever a profile is read.
    - `MEDICAL_PROFILE_UPDATED`: Logged with updated field hashes.
    - `INCIDENT_CREATED` and `INCIDENT_STATUS_CHANGED`: Logged with actor UUID and correlation trace ID.
  - Audit records cannot be updated or deleted through the application API.

---

## 3. Comprehensive Risk Register & Failure Mode Analysis

The risk register below details identified clinical, logistical, and technical failure modes, their severity, mitigations in the current codebase, and residual risk.

| Risk ID | Hazard / Failure Mode | Likelihood | Severity | Implemented Technical Mitigation in Smart Aid | Residual Risk | Recommended Future Safeguard |
| :---: | :--- | :---: | :---: | :--- | :---: | :--- |
| **RSK-01** | **GPS Drift or Inaccurate Incident Location** | Medium | Critical | High-accuracy GPS acquisition (`LocationAccuracy.high` in Flutter Geolocator); incident creation accepts coordinates validation (`-90 <= lat <= 90`, `-180 <= lon <= 180`). | Low | Add manual map pin correction sheet allowing caller to adjust coordinates. |
| **RSK-02** | **Stale or Inaccurate Hospital Capacity Feeds** | High | High | Smart ER algorithm transparently explains data source; missing congestion receives 0 positive score; reasons list warns operator if data is unverified. | Medium | Implement automated telemetry heartbeats and mandatory periodic hospital capacity re-verification. |
| **RSK-03** | **Emergency Incident Duplicate Creation (Network Retries)** | High | Medium | `Idempotency-Key` header with PostgreSQL transaction advisory lock (`pg_try_advisory_xact_lock`) returns original incident if duplicate key submitted. | Minimal | Verified E2E. Standardize client-side automatic idempotency UUID generation for all network retries. |
| **RSK-04** | **Concurrent Volunteer Mission Acceptance Race Condition** | High | High | Database row-level pessimistic lock (`SELECT * FROM incidents WHERE id = :id FOR UPDATE`) in `VolunteerService.java` ensures only the first responder wins assignment; subsequent attempts return `409 Conflict`. | Minimal | Fully verified in unit and automated E2E tests. |
| **RSK-05** | **Mobile Network Disconnection During Emergency SOS** | Medium | Critical | In current V1, request fails with network error. No offline queue exists. | **High** | **Top Priority:** Implement local SQLite/Hive offline buffer with background sync (Roadmap Phase 2). |
| **RSK-06** | **Misinterpretation of Triage Suggestions as Formal Diagnosis** | Medium | High | Triage summary explicitly appends non-diagnostic disclaimer; priority is categorized into coarse operational tiers (`CRITICAL`, `HIGH`, `STANDARD`). | Low | Mandatory UI banner on mobile triage screen reminding users of decision-support nature. |
| **RSK-07** | **Unauthorized Access to Sensitive Patient Medical Records** | Low | High | Strict `@PreAuthorize` enforcement; JWT principal extraction; patient consent flag; immutable `audit_logs` trail on every profile read. | Low | Implement column-level database encryption (AES-256) for allergy and medication text fields. |
| **RSK-08** | **Unauthenticated STOMP WebSocket Eavesdropping** | Medium | High | `StompAuthChannelInterceptor.java` intercepts `CONNECT` frames and validates JWT Bearer tokens before binding the user session to the channel. | Minimal | Enforce TLS (WSS) in production deployment. |

---

*Audited and certified by Master Clinical Safety & Security Systems Auditor on 2026-11-16.*
