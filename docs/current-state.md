# Current-state inspection — 2026-09-26

## Evidence inspected

The repository contained only untracked root files: `README.md`, `.env.example`, and `.gitignore`; there were no project directories or committed history. A complete file inventory found no JavaScript, Java, Dart, Flutter, Firebase configuration, source code, tests, migrations, assets, or design files.

## Existing architecture and features

There was no frontend, backend, database model, authentication, Firebase Authentication/Firestore use, SOS implementation, GPS/location implementation, map integration, user/volunteer/EMS functionality, dashboard, or incident structure to migrate.

The original README described an uncreated first auth slice and a container deployment. That description was not backed by source files and conflicts with the native-only requirement. It is therefore treated as stale planning text, not implemented functionality.

## UI and reusable material

There were no UI patterns or reusable code. The useful product constraints preserved from the scaffold are the product safety wording, Riverpod/Dio direction, JWT/RBAC direction, and the intention to use PostgreSQL/PostGIS. They are now made concrete in the target architecture.

## Technical debt and migration strategy

- Remove the inaccurate Docker reference from documentation; do not create any Docker files or container instructions.
- Replace claims of completion with evidence-based implementation status.
- Establish a native monorepo with versioned SQL migrations, a Spring Boot API, and a Flutter client.
- Migrate only through APIs: Flutter never connects directly to PostgreSQL and Firebase is not introduced as a system of record.
- Build vertical slices in order: auth, manual SOS/incident, responder dispatch, EMS/Smart ER; use local/mock notification and resource data until a verified provider or authority is configured.

## Environment finding

Java 25, Maven 3.9.14, Flutter 3.44.8, and Dart 3.12.2 are installed. The `psql` command was not on `PATH` at inspection time, so database provisioning cannot be claimed verified until PostgreSQL/PostGIS is installed/configured locally.

## Implementation progress after inspection

The current native implementation now includes the auth/SOS vertical slice, a volunteer response slice, and the initial EMS coordination slice. A server-authorized volunteer can update availability and current location, view only nearby matching `SEARCHING` incidents once verified/certified, atomically accept one response, mark arrival, and complete the volunteer mission. EMS/Admin users can view non-terminal incidents, inspect an auditable status timeline through the API, start EMS coordination only from a permitted state, and inspect a transparent Smart ER recommendation comparison when verified hospital capability data exists.

The Flutter app now also includes localized user navigation, persisted language choice, optional structured non-diagnostic check-in before SOS, incident history/detail timeline, user-controlled medical profile, emergency-contact CRUD, and a notification inbox. Medical-profile access and change actions are audited. The resources page remains intentionally empty until verified resource data is supplied. Volunteer verification, certification issuance, role management, ambulance control, hospital selection, external navigation, training, disaster operations, analytics, and admin workflows remain unimplemented administrative or operational work; no user-facing workflow claims otherwise.

## Native integration evidence — 2026-10-03

The native PostgreSQL 18 database and PostGIS extension have been verified locally. Flyway validated and applied five migrations, and the API started successfully against that database. The opt-in `SMARTAID_DEMO_SEED=true` scenario creates only fictional local accounts, two simulated incidents, a verified responder, and fictional hospital capabilities for a controlled presentation.

The live local API smoke test verified citizen, volunteer, and EMS login roles; citizen incident history; verified volunteer eligibility and nearby incident visibility; EMS dashboard counts; two explainable Smart ER recommendations; and a `401` response for unauthenticated EMS access. This is integration evidence for the local prototype, not emergency-service or medical validation. See `docs/demo-runbook.md` for presentation controls.

---

## ISEF Audit and Submission Package — 2026-11-16

An independent technical audit was conducted across the entire repository (366 files). Key audit findings:

- **Backend:** 17 Spring Boot controllers, 58 unique REST endpoints, 20/20 backend tests passing.
- **Mobile:** 46 Dart source files, 54/54 Flutter tests passing across 6 device profiles and bilingual layouts.
- **E2E:** 14/14 automated end-to-end stages passing (`scripts/test-end-to-end.ps1`).
- **Database:** 20 tables across V1–V7 Flyway migrations, PostGIS spatial columns verified.
- **Smart ER Algorithm (source of truth — `SmartErService.java`):** `Score = 0.30*(Travel) + 0.30*(Capability) + 0.25*(Specialty) + 0.15*(Congestion)`. Empirical comparison: Smart Aid 88.6/100, Nearest-only 54.2/100, Random 48.7/100 (weighted scenario simulation).
- **Claims purged:** "40% faster response" and "85% triage accuracy" removed from all materials as unverified.
- **F03 (Multi-Responder):** Partial — unique constraint `uq_emergency_responses_incident` limits to one volunteer per incident; multi-volunteer task splitting absent.
- **F06 (Offline Mode):** Not implemented — displays offline error banner only.
- **F09–F13 (Pharmacy, Lab, Blood Bank, Medical Services, Delivery):** Not implemented.

A complete ISEF submission package (25 files) was generated in `Smart_Aid_ISEF_Submission/`, including audit reports, feature matrices, API inventory, role/permission matrix, test case matrix, presentation slides, PDF export, abstract, and poster layout template. No original source files were modified.

