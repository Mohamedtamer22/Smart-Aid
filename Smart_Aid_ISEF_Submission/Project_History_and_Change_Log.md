# Smart Aid — Project History, Scope Evolution & Traceability Change Log

**Project:** Smart Aid  
**Team:** FirstLine  
**Audit Date:** 2026-11-16  
**Audited Artifacts:** Git repository commit `73cd6bb`, `docs/current-state.md`, `docs/PROJECT_AUDIT.md`, `docs/FEATURE_ACCEPTANCE_MATRIX.md`, `docs/IMPLEMENTATION_PROGRESS.md`, `final_report.md`, and application source files.

---

## 1. Project Genesis & Scope Evolution Timeline

### Phase 0: Initial Scaffold & Requirements Definition (2026-09-26)
- **Initial State:** The repository contained only root template files (`README.md`, `.env.example`, `.gitignore`). No source code, tests, or database migrations were present.
- **Legacy Planning Assumptions:** Early planning text suggested a Docker container deployment and generic microservices.
- **Architectural Course Correction:** During current-state inspection (`docs/current-state.md`), the team explicitly eliminated containerization in favor of a **Native Single-Machine Architecture** on Windows (Java 17/21 Spring Boot + PostgreSQL 18 & PostGIS + Flutter 3.44.8) to eliminate container virtualization overhead, ease local debugging, and enable predictable offline performance.

### Phase 1: Database Architecture & Core Vertical Slices (2026-09-27 to 2026-10-03)
- **Database Schema (`V1__initial_schema.sql`):** Created 17 core tables with PostGIS `geography(POINT, 4326)` columns, GIST spatial indexing, triggers, and immutable audit logs.
- **Reference Data (`V2__reference_data.sql`):** Seeded baseline roles (`USER`, `VOLUNTEER`, `EMS`, `ADMIN`), initial emergency types (`MEDICAL`, `CARDIAC`, `TRAUMA`, `ACCIDENT`, `OTHER`), and initial system weights.
- **Citizen SOS & Idempotency:** Implemented one-tap emergency incident creation with unique `Idempotency-Key` headers to protect against network retry duplication.
- **Deterministic Triage:** Implemented 6-symptom structured triage decision support (`TriageService.java`) producing priority levels (`CRITICAL`, `HIGH`, `STANDARD`).
- **Medical Profile & Contacts:** Established patient-controlled emergency medical profile and emergency contacts CRUD.

### Phase 2: Volunteer Dispatch & Response Workflows (2026-10-04 to 2026-10-09)
- **Schema Expansion (`V3__volunteer_response_workflow.sql`):** Added timestamps for volunteer scene arrival (`arrived_at`) and task completion (`completed_at`). Implemented unique constraint `uq_emergency_responses_incident` enforcing a single assigned volunteer per incident.
- **Smart Dispatch Algorithm:** Implemented multi-factor responder scoring (`SmartDispatchService.java`): distance (45%), travel time (25%), skill match (20%), and certification status (10%).
- **Concurrency Protection:** Implemented pessimistic database locking (`SELECT FOR UPDATE`) on incident acceptance to ensure that only the first responder to accept is assigned.
- **Live Event Broadcasting:** Configured STOMP over WebSocket (`/ws`) for instant incident status updates (`/topic/incidents/{incidentId}`).

### Phase 3: EMS Command Center, Smart ER & Advanced Modules (2026-10-10 to 2026-10-17)
- **Schema Refinements (`V4`, `V5`, `V6`, `V7`):**
  - `V4`: Aligned `eta_minutes` to `INTEGER`.
  - `V5`: Aligned `estimated_congestion` to `INTEGER` (0-100%).
  - `V6`: Added `HOSPITAL` role and `hospital_partner_requests` onboarding queue.
  - `V7`: Established `incident_idempotency_keys` table with PostgreSQL transaction-level advisory locking (`pg_try_advisory_xact_lock`).
- **Smart ER Recommendation Engine:** Multi-factor destination scoring (`SmartErService.java`) balancing travel time (30%), critical care capabilities (30%), specialty match (25%), and reported congestion (15%).
- **Interactive Destination Selection:** Added EMS dashboard controls to review candidates and confirm or override destination selection.
- **Disaster Management:** Mass-casualty triage adjustment and disaster zone coordination (`DisasterService.java`).
- **Training Academy:** Volunteer education modules (CPR & AED, Triage Protocols, Trauma First Response) with automated quiz evaluation (`TrainingService.java`).
- **Executive Analytics:** Empirical 3-way research benchmark endpoint (`GET /api/analytics/research/smart-er-comparison`).

### Phase 4: Performance Optimization & Mobile Hardening (2026-10-18 to 2026-10-20)
- **Root-Cause Analysis of Mobile Latency:** Addressed slow screen loads in medical profile, contacts, and notifications.
- **Riverpod State Caching:** Migrated from `FutureProvider.autoDispose` to persistent `AsyncNotifier` caches to prevent white-screen reloading.
- **Optimistic UI Updates:** Instant in-memory updates for notification read states and contact changes without full-page re-fetching.
- **In-Memory Token Cache:** Resolved 50-200 ms Android KeyStore decryption delays by caching access tokens in memory after first read.
- **APK Compression:** Resolved ProGuard R8 warnings and built AOT release APK (`SmartAid-V1.apk`), reducing package size by 70% from 192 MB to 56.6 MB (59.7 MB file size).

---

## 2. Comprehensive Traceability Matrix: Old Scope vs. Implemented V1 vs. Reconciled Scope

| Baseline Group | Original / Proposed Scope | Current Verified Implementation (V1) | Status & Variance | Action / Disposition for ISEF |
| :--- | :--- | :--- | :--- | :--- |
| **Foundational: SOS Intake** | Citizen emergency reporting with GPS, attachments, and retry protection | Full idempotent SOS intake (`IncidentController`, `PulsingSosButton`), advisory locks, PostGIS points | **VERIFIED IMPLEMENTED** (Attachments not implemented; notes only) | Highlight idempotent emergency creation and spatial indexing |
| **F01 — Advanced AI Triage** | Advanced AI/ML diagnostic triage assessing patient condition | Deterministic clinical decision rules (`TriageService.java`) mapping 6 symptoms to priority (`CRITICAL`, `HIGH`, `STANDARD`) | **RULE-BASED (NOT AI/ML)** (No machine learning model or diagnostic claim) | Re-label honestly as "Deterministic Clinical Decision-Support Triage Rules"; remove AI/ML claims |
| **F02 — Smart Dispatch** | Multi-factor volunteer assignment based on ETA, skills, and availability | Verified spatial dispatch (`SmartDispatchService.java`): Haversine distance, 30 km/h ETA, skills, certification check | **VERIFIED IMPLEMENTED** (Straight-line ETA; no live traffic API) | Present as distance-and-skill-based responder matching |
| **F03 — Multi-Responder Coordination** | Coordinate multiple responders, task splitting (CPR, AED, crowd control) | Single volunteer assignment per incident (`uq_emergency_responses_incident`) + EMS ambulance dispatch | **PARTIAL** (No multiple volunteer task-splitting; single volunteer + EMS only) | Document single-volunteer + EMS coordination; list task-splitting as future roadmap |
| **F04 — Smart Hospital Recommendation** | Real-time hospital capacity and multi-factor recommendation algorithm | Implemented `SmartErService.java` (travel 30%, capability 30%, specialty 25%, congestion 15%); interactive destination selection | **ALGORITHM IMPLEMENTED / FEEDS SIMULATED** (No live external hospital FHIR/HL7 integration) | Core research focus; evaluate algorithm performance on controlled benchmark dataset |
| **F05 — Command Center (ECC)** | Central operational command center for EMS and dispatch operators | Implemented via Flutter Web / Mobile EMS Dashboard (`ems_dashboard_page.dart`) and Admin Dashboard | **VERIFIED IMPLEMENTED** (Built in Flutter, not Angular/React) | Present Flutter-based Emergency Operations Dashboard |
| **F06 — Offline Emergency Mode** | Offline emergency reporting, local queue, and background synchronization | Local UI error message on network failure; no local database or sync queue implemented | **NOT IMPLEMENTED** (Missing SQLite/Hive and background sync engine) | Label as not implemented; prioritize in Implementation Roadmap |
| **F07 — Smart AED & Equipment Finder** | Find nearby AEDs and emergency equipment with verified status | Database table `aed_devices`, PostGIS coordinates, `AedController`, segmented tab in mobile app | **VERIFIED IMPLEMENTED** (Tested with local seed data; no IoT sensor feeds) | Present directory of verified emergency equipment |
| **F08 — Disaster Management** | Mass-casualty incident management and resource coordination | Implemented `DisasterController`, `DisasterService`, `disaster_management_page.dart` | **VERIFIED IMPLEMENTED** (Unit tested in `DisasterServiceTest`) | Present disaster escalation and multi-casualty triage mode |
| **F09 — Smart Pharmacy & Emergency Supplies** | Pharmacy directory, medicine availability, first-aid emergency supplies | No pharmacy tables, controllers, or UI screens exist in repository | **NOT IMPLEMENTED** | Document gap; keep in Implementation Roadmap |
| **F10 — Smart Lab** | Laboratory center directory, test booking, and result sharing | No laboratory tables, controllers, or UI screens exist in repository | **NOT IMPLEMENTED** | Document gap; exclude from current system claims |
| **F11 — Smart Blood Bank** | Blood bank inventory, search, and donor request workflows | Blood type stored in medical profile; no blood bank inventory or request module | **NOT IMPLEMENTED** | Document gap; exclude from current system claims |
| **F12 — Smart Medical Services** | Discovery and booking for doctors, radiology, physical therapy, home care | No medical services tables, controllers, or UI screens exist in repository | **NOT IMPLEMENTED** | Document gap; exclude from current system claims |
| **F13 — Smart Medical Delivery** | Permitted medical supply delivery ordering and tracking | Ambulance tracking exists; no medical supply delivery or courier workflow | **NOT IMPLEMENTED** | Document gap; exclude from current system claims |
| **F14 — Smart Medical ID** | Emergency medical profile (blood type, allergies, medications, contacts) | Implemented `medical_profiles`, `emergency_contacts`, `ProfileController`, audited access | **VERIFIED IMPLEMENTED** (Patient-owned, self-reported, fully audited) | Highlight privacy controls, consent toggle, and audit logging |
| **F15 — Smart Medical Handover** | Structured digital handover to EMS and receiving hospital staff | Status history records transitions to `AT_HOSPITAL`/`RESOLVED`; no separate handover document | **PARTIAL** (Basic status transition notes; no formal digital handover form) | Document current transition notes; schedule digital handover in roadmap |
| **F16 — Smart Training Academy** | Healthcare education, CPR/AED lessons, quizzes, and certificates | Implemented `training_courses`, `training_lessons`, `TrainingService`, quizzes, passing score 80% | **VERIFIED IMPLEMENTED** (Educational simulation; mock content flag = true) | Present self-paced educational modules; state clearly not accredited |
| **F17 — Emergency Risk Analytics** | Incident heatmaps, response time analytics, research benchmarks | Implemented `AnalyticsController`, `AnalyticsService`, research comparison (Nearest vs. Random vs. Smart ER) | **VERIFIED IMPLEMENTED** (Research comparison works; overview KPIs contain demo constants) | Highlight empirical strategy comparison; identify hardcoded demo KPIs |

---

## 3. Explicit Boundary Enforcement: Future Plan & Optional Backlog

### 3.1 Formal Future Plan: Smart Fall & Accident Detection ONLY
- **Current Evidence:** The database check constraint on `incidents.source` includes `'SMARTWATCH'`, `'SENSOR'`, `'CRASH'`, but the application exclusively creates incidents with `source = 'MANUAL'`. No wearable SDK, accelerometer signal processing, or accident-detection model exists in the codebase.
- **Audit Decision:** In strict adherence to Section 1.6 and Section 13 of the project audit prompt, **Smart Fall & Accident Detection is designated exclusively as the formal Future Plan**. It is not claimed as an existing or working feature.

### 3.2 Optional Backlog (Kept Separate from Baseline 17)
The following proposed ideas were investigated and confirmed absent from the codebase:
1. Smart Doctor discovery, booking, or telemedicine.
2. Unified Medical History (distinct from the emergency Medical ID).
3. Medication Reminder engine.
4. Chronic Care follow-up workflows.
5. Home Care request integration.
6. Health Insurance verification.
These remain in an internal research backlog and are excluded from the baseline feature count and competition deliverables.

---

*Reconciled and certified by Master Project Auditor on 2026-11-16.*
