# Smart Aid — Database Schema Inventory & Architectural Gap Analysis

**Project:** Smart Aid  
**Audit Date:** 2026-11-16  
**Database Engine:** PostgreSQL 18.x with PostGIS Spatial Extension  
**Schema Manager:** Flyway (`V1__initial_schema.sql` through `V7__incident_idempotency.sql`)  
**Audited Location:** `backend/src/main/resources/db/migration/` and `database/`

---

## 1. Actual Implemented Schema Inventory

The current production database schema is managed across seven Flyway migrations. It comprises **20 relational and spatial tables**, **6 geography trigger functions**, **6 spatial GIST indexes**, and **18 standard B-tree indexes**.

### 1.1 Existing Tables and Entity Structure

```
                  ┌───────────────┐
                  │     users     │◄─────────────────┐
                  └──────┬────────┘                  │
                         │ 1                         │
         ┌───────────────┼───────────────┐           │
         │ 1             │ 1             │ 1         │
         ▼               ▼               ▼           │
┌────────────────┐┌──────────────┐┌──────────────┐   │
│medical_profiles││  user_roles  ││refresh_tokens│   │
└────────────────┘└──────┬───────┘└──────────────┘   │
                         │ *                         │
                         ▼                           │
                  ┌───────────────┐                  │
                  │     roles     │                  │
                  └───────────────┘                  │
                                                     │
         ┌───────────────────────────────────────────┤
         │ 1                                         │ 1
         ▼                                           ▼
┌──────────────────┐                       ┌──────────────────┐
│emergency_contacts│                       │volunteer_profiles│
└──────────────────┘                       └────────┬─────────┘
                                                    │ 1
                                        ┌───────────┴───────────┐
                                        │ *                     │ *
                                        ▼                       ▼
                                ┌────────────────┐      ┌──────────────────────┐
                                │volunteer_skills│      │volunteer_certific'ns │
                                └───────┬────────┘      └──────────┬───────────┘
                                        │ *                        │ *
                                        ▼                          ▼
                                ┌────────────────┐      ┌──────────────────────┐
                                │     skills     │      │    certifications    │
                                └────────────────┘      └──────────────────────┘
```

#### Detailed Table Specifications

1. **`roles` (`V1`, `V2`, `V6`)**:
   - `id`: `SMALLSERIAL PRIMARY KEY`
   - `code`: `VARCHAR(32) NOT NULL UNIQUE` (Values: `USER`, `VOLUNTEER`, `EMS`, `ADMIN`, `HOSPITAL`)
   - `created_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`

2. **`users` (`V1`)**:
   - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
   - `email`: `VARCHAR(254) NOT NULL UNIQUE`
   - `password_hash`: `VARCHAR(255) NOT NULL` (BCrypt encoded)
   - `display_name`: `VARCHAR(120) NOT NULL`
   - `enabled`: `BOOLEAN NOT NULL DEFAULT TRUE`
   - `created_at`, `updated_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`
   - *Indexes:* `idx_users_email` (B-tree on `email`)

3. **`user_roles` (`V1`)**:
   - Composite PK: `(user_id, role_id)` referencing `users(id)` and `roles(id)`

4. **`refresh_tokens` (`V1`)**:
   - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id`: `UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE`
   - `token_hash`: `VARCHAR(64) NOT NULL UNIQUE` (SHA-256 hashed)
   - `expires_at`: `TIMESTAMPTZ NOT NULL`
   - `revoked_at`: `TIMESTAMPTZ`
   - `created_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`
   - *Indexes:* `idx_refresh_tokens_user` (B-tree on `user_id`)

5. **`medical_profiles` (`V1`)**:
   - `user_id`: `UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE`
   - `blood_type`: `VARCHAR(8)` (e.g. `O+`, `A-`, `AB+`)
   - `allergies`: `TEXT`
   - `medications`: `TEXT`
   - `emergency_notes`: `TEXT`
   - `sharing_consent`: `BOOLEAN NOT NULL DEFAULT FALSE`
   - `updated_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`

6. **`emergency_contacts` (`V1`)**:
   - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id`: `UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE`
   - `full_name`: `VARCHAR(120) NOT NULL`
   - `relationship`: `VARCHAR(80)`
   - `phone`: `VARCHAR(32) NOT NULL`
   - `is_primary`: `BOOLEAN NOT NULL DEFAULT FALSE`
   - `created_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`

7. **`emergency_types` (`V1`, `V2`)**:
   - `id`: `SMALLSERIAL PRIMARY KEY`
   - `code`: `VARCHAR(40) NOT NULL UNIQUE` (`MEDICAL`, `CARDIAC`, `TRAUMA`, `ACCIDENT`, `OTHER`)
   - `label`: `VARCHAR(100) NOT NULL`

8. **`incidents` (`V1`)**:
   - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
   - `reporter_id`: `UUID NOT NULL REFERENCES users(id)`
   - `emergency_type_id`: `SMALLINT NOT NULL REFERENCES emergency_types(id)`
   - `source`: `VARCHAR(20) NOT NULL CHECK (source IN ('MANUAL','SMARTWATCH','SENSOR','CRASH','OTHER'))`
   - `status`: `VARCHAR(32) NOT NULL CHECK (status IN ('NEW','SEARCHING','RESPONDER_ASSIGNED','EMS_ASSIGNED','AMBULANCE_ASSIGNED','IN_TRANSIT','HOSPITAL_SELECTED','AT_HOSPITAL','RESOLVED','CANCELLED'))`
   - `priority`: `VARCHAR(16) NOT NULL DEFAULT 'STANDARD' CHECK (priority IN ('LOW','STANDARD','HIGH','CRITICAL'))`
   - `latitude`: `DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90)`
   - `longitude`: `DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180)`
   - `location`: `GEOGRAPHY(POINT, 4326)` (automatically populated via trigger `trg_incident_geography`)
   - `notes`: `VARCHAR(1000)`
   - `created_at`, `updated_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`
   - *Indexes:* `idx_incidents_reporter` (`reporter_id, created_at DESC`), `idx_incidents_status` (`status, created_at DESC`), `idx_incidents_location` (GIST on `location`)

9. **`incident_status_history` (`V1`)**:
   - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
   - `incident_id`: `UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE`
   - `from_status`: `VARCHAR(32)`
   - `to_status`: `VARCHAR(32) NOT NULL`
   - `actor_id`: `UUID REFERENCES users(id)`
   - `reason`: `VARCHAR(500)`
   - `created_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`
   - *Indexes:* `idx_status_history_incident` (`incident_id, created_at`)

10. **`incident_idempotency_keys` (`V7`)**:
    - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
    - `reporter_id`: `UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE`
    - `request_key`: `VARCHAR(128) NOT NULL`
    - `request_fingerprint`: `VARCHAR(64) NOT NULL`
    - `incident_id`: `UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE`
    - `created_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`
    - *Constraints:* `uq_incident_idempotency_key UNIQUE (reporter_id, request_key)`
    - *Indexes:* `idx_incident_idempotency_incident` on `incident_id`

11. **`triage_assessments` (`V1`)**:
    - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
    - `incident_id`: `UUID NOT NULL UNIQUE REFERENCES incidents(id) ON DELETE CASCADE`
    - `conscious`, `breathing`, `severe_bleeding`, `chest_pain`, `fall_occurred`, `traffic_accident`: `BOOLEAN`
    - `summary`: `VARCHAR(1000) NOT NULL`
    - `rule_version`: `VARCHAR(32) NOT NULL`
    - `created_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`

12. **`volunteer_profiles` (`V1`)**:
    - `user_id`: `UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE`
    - `verified`: `BOOLEAN NOT NULL DEFAULT FALSE`
    - `available`: `BOOLEAN NOT NULL DEFAULT FALSE`
    - `latitude`, `longitude`: `DOUBLE PRECISION`
    - `location`: `GEOGRAPHY(POINT, 4326)` (populated via trigger)
    - `updated_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`
    - *Indexes:* `idx_volunteers_available` (`available, verified`), `idx_volunteers_location` (GIST on `location`)

13. **`skills` & `volunteer_skills` (`V1`)**:
    - Reference codes (`CPR`, `AED`, `FIRST_AID`) and volunteer mapping.

14. **`certifications` & `volunteer_certifications` (`V1`)**:
    - Credential verification (`BLS`, `ALS`, `PARAMEDIC`) with `verified_at` and `expires_at TIMESTAMPTZ`.

15. **`hospitals` (`V1`, `V5`)**:
    - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
    - `name`: `VARCHAR(160) NOT NULL UNIQUE`
    - `latitude`, `longitude`: `DOUBLE PRECISION NOT NULL`
    - `location`: `GEOGRAPHY(POINT, 4326)` (GIST index `idx_hospitals_location`)
    - `verified`: `BOOLEAN NOT NULL DEFAULT FALSE`
    - `estimated_congestion`: `INTEGER CHECK (estimated_congestion BETWEEN 0 AND 100)`
    - `updated_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`

16. **`hospital_specialties` & `hospital_resources` (`V1`)**:
    - Specific clinical capabilities: `hospital_id`, `specialty` (`CARDIOLOGY`, `TRAUMA`, `EMERGENCY`), `verified BOOLEAN`.
    - Specific physical resources: `hospital_id`, `resource_code` (`CATH_LAB`, `TRAUMA_BAY`, `RESUSCITATION`), `available BOOLEAN`, `verified_at TIMESTAMPTZ`.

17. **`ambulances` & `ambulance_tracking` (`V1`)**:
    - Fleet units: `call_sign VARCHAR(50) UNIQUE`, `status` (`AVAILABLE`, `ASSIGNED`, `EN_ROUTE`, `ARRIVED`, `TRANSPORTING`, `AT_HOSPITAL`, `COMPLETED`), `location GEOGRAPHY(POINT, 4326)`.
    - Historical tracking trail: `ambulance_tracking` recording coordinates and `recorded_at TIMESTAMPTZ`.

18. **`emergency_responses` (`V1`, `V3`, `V4`)**:
    - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
    - `incident_id`: `UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE`
    - `volunteer_id`: `UUID REFERENCES volunteer_profiles(user_id)`
    - `ambulance_id`: `UUID REFERENCES ambulances(id)`
    - `response_status`: `VARCHAR(32) NOT NULL CHECK (response_status IN ('ACCEPTED','ARRIVED','COMPLETED','CANCELLED'))`
    - `eta_minutes`: `INTEGER CHECK (eta_minutes >= 0)`
    - `accepted_at`, `arrived_at`, `completed_at`, `updated_at`: `TIMESTAMPTZ`
    - *Constraint:* `uq_emergency_responses_incident UNIQUE (incident_id)`

19. **`aed_devices` (`V1`)**:
    - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
    - `resource_type`: `VARCHAR(32) NOT NULL CHECK (resource_type IN ('AED','FIRST_AID','OTHER_APPROVED_RESOURCE'))`
    - `label`: `VARCHAR(160) NOT NULL`
    - `latitude`, `longitude`: `DOUBLE PRECISION NOT NULL`
    - `location`: `GEOGRAPHY(POINT, 4326)` (GIST index `idx_aed_location`)
    - `availability_status`: `VARCHAR(32) NOT NULL`
    - `verified`: `BOOLEAN NOT NULL DEFAULT FALSE`
    - `updated_at`: `TIMESTAMPTZ NOT NULL DEFAULT now()`

20. **`notifications`, `training_courses`, `training_lessons`, `training_results`, `audit_logs`, `system_settings` (`V1`)**:
    - In-app notification store with `read_at TIMESTAMPTZ`.
    - Educational training courses with quizzes and numerical scores.
    - Immutable security audit logs (`actor_id`, `action`, `entity_type`, `entity_id`, `trace_id`, `metadata JSONB`).
    - Key-value JSONB settings table storing default algorithm weights.

21. **`hospital_partner_requests` (`V6`)**:
    - Onboarding request queue for unverified hospital entities (`status IN ('PENDING', 'APPROVED', 'DECLINED')`).

---

## 2. Database Architectural Gap Analysis

To achieve the complete target scope of the 17 baseline capability groups, the following schema additions are required:

### 2.1 Missing Schema Components by Feature Group

#### F03 — Multi-Responder Task Coordination
*Current Limitation:* `emergency_responses` has `uq_emergency_responses_incident UNIQUE (incident_id)`. Only a single volunteer can be assigned per incident.
*Required Schema Addition:*
```sql
CREATE TABLE incident_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    assigned_responder_id UUID REFERENCES volunteer_profiles(user_id),
    task_type VARCHAR(40) NOT NULL CHECK (task_type IN ('CPR', 'AED_RETRIEVAL', 'FIRST_AID', 'CROWD_CONTROL', 'PATIENT_TRANSPORT')),
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    instructions VARCHAR(500),
    assigned_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_incident_tasks_incident ON incident_tasks(incident_id);
CREATE INDEX idx_incident_tasks_responder ON incident_tasks(assigned_responder_id, status);
```

#### F06 — Offline Emergency Mode & Synchronization Queue
*Current Limitation:* No client-side or server-side sync queue tables exist.
*Required Server Schema Addition:*
```sql
CREATE TABLE offline_sync_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_device_id VARCHAR(128) NOT NULL,
    client_generated_id UUID NOT NULL,
    operation_type VARCHAR(40) NOT NULL,
    payload JSONB NOT NULL,
    captured_offline_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    conflict_resolution VARCHAR(32) NOT NULL DEFAULT 'APPLIED',
    CONSTRAINT uq_offline_client_op UNIQUE (client_device_id, client_generated_id)
);
```

#### F09 — Smart Pharmacy & Emergency Supplies
*Current Limitation:* Zero tables exist for pharmacies or inventory.
*Required Schema Addition:*
```sql
CREATE TABLE pharmacies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(160) NOT NULL,
    license_number VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(32) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    is_24_hours BOOLEAN NOT NULL DEFAULT FALSE,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_pharmacies_location ON pharmacies USING GIST(location);

CREATE TABLE emergency_supplies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    category VARCHAR(60) NOT NULL CHECK (category IN ('FIRST_AID_KIT', 'GAUZE_BANDAGE', 'HEMOSTATIC_DRESSING', 'BURN_CARE', 'SPLINT', 'ANTISEPTIC')),
    requires_prescription BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE pharmacy_supplies_inventory (
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    supply_id UUID NOT NULL REFERENCES emergency_supplies(id) ON DELETE CASCADE,
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    last_verified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (pharmacy_id, supply_id)
);
```

#### F10 — Smart Lab
*Current Limitation:* Zero laboratory tables exist.
*Required Schema Addition:*
```sql
CREATE TABLE medical_laboratories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(160) NOT NULL,
    license_number VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(32) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    verified BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE TABLE lab_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    laboratory_id UUID NOT NULL REFERENCES medical_laboratories(id) ON DELETE CASCADE,
    test_code VARCHAR(40) NOT NULL,
    test_name VARCHAR(160) NOT NULL,
    turnaround_hours INTEGER NOT NULL
);
```

#### F11 — Smart Blood Bank
*Current Limitation:* Blood type exists only as a string field in patient medical profile.
*Required Schema Addition:*
```sql
CREATE TABLE blood_banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(160) NOT NULL,
    hospital_id UUID REFERENCES hospitals(id),
    phone VARCHAR(32) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    verified BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE TABLE blood_inventory (
    blood_bank_id UUID NOT NULL REFERENCES blood_banks(id) ON DELETE CASCADE,
    blood_group VARCHAR(8) NOT NULL CHECK (blood_group IN ('O+','O-','A+','A-','B+','B-','AB+','AB-')),
    units_available INTEGER NOT NULL DEFAULT 0 CHECK (units_available >= 0),
    last_confirmed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (blood_bank_id, blood_group)
);
CREATE TABLE blood_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID REFERENCES incidents(id),
    requester_id UUID NOT NULL REFERENCES users(id),
    blood_group VARCHAR(8) NOT NULL,
    units_requested INTEGER NOT NULL CHECK (units_requested > 0),
    status VARCHAR(32) NOT NULL DEFAULT 'REQUESTED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

#### F15 — Formal Medical Handover
*Current Limitation:* Handover is currently represented only as status transitions (`AT_HOSPITAL`, `RESOLVED`) in `incident_status_history`.
*Required Schema Addition:*
```sql
CREATE TABLE medical_handovers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    ems_responder_id UUID NOT NULL REFERENCES users(id),
    receiving_hospital_id UUID NOT NULL REFERENCES hospitals(id),
    receiving_clinician_name VARCHAR(120) NOT NULL,
    vitals_summary JSONB NOT NULL,
    treatment_administered TEXT,
    handover_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledgment_signature VARCHAR(255)
);
```

---

## 3. Migration Roadmap for Proposed Schema Changes

All proposed schema changes must be delivered as sequential Flyway migrations following project rules:
1. `V8__multi_responder_tasks.sql`: Drops single-volunteer constraint and establishes `incident_tasks`.
2. `V9__pharmacy_and_emergency_supplies.sql`: Creates `pharmacies`, `emergency_supplies`, and `pharmacy_supplies_inventory`.
3. `V10__blood_bank_coordination.sql`: Creates `blood_banks`, `blood_inventory`, and `blood_requests`.
4. `V11__laboratories_and_medical_services.sql`: Creates `medical_laboratories`, `lab_services`, and provider catalogs.
5. `V12__digital_medical_handover.sql`: Creates `medical_handovers` and acknowledgment trail.

**Non-Negotiable Rule Confirmation:** Zero database migrations were applied or modified during this audit. The above gap analysis represents the verified delta between current V1 and target architecture.

---

*Audited and formulated by Master Project Auditor on 2026-11-16.*
