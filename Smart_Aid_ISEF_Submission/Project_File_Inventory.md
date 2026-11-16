# Smart Aid — Master Project File Inventory & Workspace Audit

**Audit Date:** 2026-11-16  
**Audited Directory:** D:\hamo\Projects\SmartAid  
**Output Target:** D:\hamo\Projects\SmartAid\Smart_Aid_ISEF_Submission  
**Audit Standard:** ISEF / Scientific Evidence-Based Independent Software Audit  

---

## 1. Workspace Inventory Summary

The repository D:\hamo\Projects\SmartAid was completely inspected. A full recursive traversal excluding ephemeral build artifacts (.git, uild, .dart_tool, .gradle, .idea, 	arget, 
ode_modules) identified **366 source, configuration, documentation, and asset files**.

### Category Breakdown

| Category | File Count | Primary Languages / Formats | Key Root / Subdirectory | Purpose & Scope |
| :--- | :---: | :--- | :--- | :--- |
| **Backend Service** | 98 | Java 17/21, YAML, XML, SQL | ackend/src/main, ackend/src/test | Spring Boot 3.5.7 REST APIs, Spring Security 6, STOMP WebSockets, JPA entities, repositories, and unit tests |
| **Database Migrations** | 7 | PostgreSQL SQL (Flyway) | ackend/src/main/resources/db/migration/ | Versioned schema migrations V1 to V7 with PostGIS extensions, spatial indexing, constraints, and audit tables |
| **Mobile Application** | 82 | Dart (Flutter 3.44.8 / Dart 3.12) | mobile/lib/, mobile/test/ | Riverpod 3.0, Dio 5.9, Flutter Map, feature-first UI pages, widget test suites, and localization |
| **Mobile Platforms** | 134 | Gradle, XML, Kotlin/Java, C++ | mobile/android/, mobile/ios/, mobile/web/ | Native Android wrapper (minSdk 21, targetSdk 34), iOS wrapper, and Flutter Web container |
| **Database Scripts** | 2 | SQL | database/ | ootstrap.sql and init_smartaid.sql for initial local database setup |
| **Operational Scripts** | 12 | PowerShell (.ps1), Batch (.bat) | scripts/, workspace root | E2E test harness (	est-end-to-end.ps1), verify scripts, Android APK builders, startup scripts |
| **Project Documentation** | 25 | Markdown (.md) | docs/, workspace root | Project encyclopedia (inal_report.md), API contract, architecture, acceptance matrix, research plan |
| **Binaries & Assets** | 6 | APK, PNG, TXT, ENV | Workspace root, mobile/assets/ | Compiled SmartAid-V1.apk (59.7 MB), branding logo, .env, .env.example, 	unnel_url.txt |
| **Total Inspected** | **366** | — | — | **Complete Native Single-Machine Platform** |

---

## 2. Detailed Technical Inventory by Functional Group

### 2.1 Backend Core Modules (ackend/src/main/java/com/smartaid/platform/)

The backend is structured into domain packages:

1. **dmin**:
   - AdminController.java: Endpoints for executive overview, user roster, role patch, volunteer verification, hospital addition, and audit log inspection.
   - AdminService.java: User/volunteer administration and system KPI aggregations.
   - AdminDtos.java: Request and response DTOs for administrative operations.
2. **nalytics**:
   - AnalyticsController.java: GET /api/analytics/dashboard and GET /api/analytics/research/smart-er-comparison.
   - AnalyticsService.java: Calculates emergency statistics and executes the empirical 3-way research comparison (Nearest vs. Random vs. Smart ER).
   - AnalyticsDtos.java: Research comparison data transfer objects.
3. **udit**:
   - AuditLog.java, AuditLogRepository.java, AuditService.java: Immutable security audit trail recording entity mutations, actor UUID, timestamp, action type, and JSON metadata.
4. **uth**:
   - AuthController.java: POST /api/auth/register, /login, /refresh, /logout.
   - AuthService.java: BCrypt credential verification, short-lived JWT issuing, SHA-256 hashed refresh token rotation.
   - HospitalPartnerController.java: Pending partner onboarding (GET /api/hospital-partner/me).
   - UserAccount.java, Role.java, RefreshToken.java, and associated Spring Data JPA repositories.
5. **config**:
   - DemoProperties.java, DispatchProperties.java, SecurityProperties.java, SmartErProperties.java, OpenApiConfig.java, TomcatNio2Configuration.java.
6. **demo**:
   - SmartAidDemoSeeder.java: Seeds controlled, fictional demonstration data (4 demo personas, 2 incidents, 3 AEDs, 3 ambulances, 3 hospitals with cardiology/trauma capabilities).
7. **disaster**:
   - DisasterController.java, DisasterService.java, DisasterDtos.java: Mass-casualty triage management and disaster zone escalation.
8. **ems**:
   - EmsController.java: GET /api/ems/dashboard, GET /api/ems/incidents/{incidentId}, POST /api/ems/incidents/{incidentId}/assign.
   - EmsService.java, EmsDtos.java: Active queue triage prioritization and EMS ambulance dispatch.
9. **exception**:
   - ApiError.java, ApiException.java, GlobalExceptionHandler.java: Standardized RFC 7807-compliant error payloads.
10. **incident**:
    - IncidentController.java: Full lifecycle endpoints (POST /api/incidents, GET /api/incidents/mine, GET /api/incidents/{id}, PATCH /api/incidents/{id}/status, POST /api/incidents/{id}/accept).
    - IncidentService.java: Incident state machine management, advisory locks, notification trigger.
    - Incident.java, IncidentStatus.java, IncidentStatusHistory.java, IncidentIdempotencyKey.java.
11. **
otification**:
    - NotificationController.java, NotificationService.java, Notification.java, NotificationRepository.java: In-app notification queue and read state.
12. **profile**:
    - ProfileController.java: /api/medical-profile and /api/emergency-contacts CRUD.
    - MedicalProfile.java, EmergencyContact.java, ProfileService.java.
13. **
esource**:
    - AedController.java, AedDevice.java, AedDeviceRepository.java: AED location directory.
    - AmbulanceController.java, Ambulance.java, AmbulanceRepository.java: Emergency fleet availability and status management.
14. **security**:
    - SecurityConfig.java: Spring Security 6 filter chain, CORS configuration, @PreAuthorize method security.
    - JwtService.java: HMAC-SHA256 token generation and validation.
    - AuthRateLimitFilter.java: In-memory IP rate limiting protecting authentication routes against brute-force attacks.
15. **smarter**:
    - SmartErController.java: GET /api/smart-er/incidents/{incidentId}/recommendations and alias GET /api/smart-er/{incidentId}.
    - HospitalController.java: GET /api/hospitals and alias GET /api/hospitals/recommendation/{incidentId}.
    - SmartErService.java: Deterministic multi-factor hospital destination ranking engine.
    - Hospital.java, HospitalSpecialty.java, HospitalResource.java, and JPA repositories.
16. **	raining**:
    - TrainingController.java, TrainingService.java, TrainingCourse.java, TrainingLesson.java, TrainingResult.java: Self-paced healthcare modules and quizzes.
17. **	riage**:
    - TriageService.java, TriageAssessment.java, TriageAssessmentRepository.java: Rule-based deterministic decision-support engine.
18. **olunteer**:
    - VolunteerController.java, SmartDispatchController.java, SmartDispatchService.java, VolunteerService.java: Spatial search (ST_DWithin), pessimistic concurrency locking (SELECT FOR UPDATE), volunteer missions.
19. **websocket**:
    - WebSocketConfig.java, StompAuthChannelInterceptor.java, WebSocketAuthorizationInterceptor.java: STOMP over WebSocket broker with JWT handshake authentication.

---

### 2.2 Database Migrations (ackend/src/main/resources/db/migration/)

All database changes are managed strictly via Flyway:

| Migration File | Size | Applied Function / Purpose |
| :--- | :---: | :--- |
| V1__initial_schema.sql | 11,509 B | PostGIS extension, 17 relational tables, spatial columns (geography(POINT, 4326)), GIST indexes, triggers |
| V2__reference_data.sql | 547 B | Reference roles (USER, VOLUNTEER, EMS, ADMIN), 5 emergency types, default algorithm weights |
| V3__volunteer_response_workflow.sql | 592 B | Adds rrived_at, updated_at, status check constraints, and unique constraint on incident_id |
| V4__align_emergency_response_eta_type.sql | 234 B | Aligns eta_minutes to INTEGER type |
| V5__align_hospital_congestion_type.sql | 229 B | Aligns estimated_congestion to INTEGER type (0-100 range) |
| V6__account_registration_paths.sql | 864 B | Adds HOSPITAL role and hospital_partner_requests onboarding queue |
| V7__incident_idempotency.sql | 764 B | Creates incident_idempotency_keys table with unique constraint (reporter_id, request_key) |

---

### 2.3 Mobile Application Architecture (mobile/lib/)

The mobile client is built with Flutter 3.44.8 and organized into core/, eatures/, and shared/:

- **Core Infrastructure (mobile/lib/core/)**:
  - config/app_config.dart: Runtime base URL configuration and persistent preferences.
  - localization/app_localizations.dart: Complete bilingual English (LTR) and Arabic (RTL) localization.
  - location/location_service.dart: High-accuracy GPS location acquisition via geolocator.
  - 
etwork/api_client.dart: Dio HTTP client with JWT interceptor, token refresh handler, and keep-alive.
  - 
etwork/incident_socket.dart: STOMP WebSocket client for real-time incident updates.
  - storage/token_store.dart: In-memory cached token access backed by lutter_secure_storage.
  - 	heme/app_theme.dart: Material 3 design tokens (
avyBlue, emergencyRed, sky, success, warning).
- **Feature Modules (mobile/lib/features/)**:
  - dmin/: Executive dashboard, user role editor, volunteer verifier, audit log viewer.
  - nalytics/: Emergency KPI visualization and interactive research comparison chart.
  - uth/: Login, registration, role selection, session management.
  - disaster/: Disaster activation, multi-casualty queue, priority adjustments.
  - emergency/: Pulsing SOS button, triage questionnaire sheet, confirmation sheet, active incident tracking.
  - ems/: Operations control center, active incident dispatch, Smart ER interactive destination confirmation.
  - home/: Citizen dashboard with one-tap SOS and active emergency cards.
  - incidents/: Historical incident list and immutable event timeline.
  - 
otifications/: Notification center with optimistic read-state updates.
  - onboarding/: 3-screen introductory educational carousel with permission requests.
  - profile/: Medical profile editor (blood type, allergies, medications), emergency contacts CRUD, settings.
  - 
esources/: Segmented directory for Hospitals, AED Devices, and Ambulances.
  - splash/: Animated launch screen with session recovery.
  - 	raining/: Self-paced healthcare courses, lesson viewer, interactive quiz dialogs.
  - olunteer/: Nearby emergency radar, mission acceptance with optimistic UI, arrival/completion logger.
- **Shared Widgets (mobile/lib/shared/widgets/)**:
  - pulsing_sos_button.dart: Dual-ring animated breathing radar SOS button.
  - quick_role_switcher.dart: Modal switcher between Citizen, Volunteer, EMS, and Admin demo accounts.
  - pp_widgets.dart: Standardized cards, status badges, metric tiles, and accessibility wrappers.

---

### 2.4 Testing Suites & Automated Scripts

- **Backend Tests (ackend/src/test/java/)**: 11 test classes containing **20 unit and service tests** covering Spring Security rate limiting, Smart Dispatch scoring, Smart ER scoring, Triage decision rules, Disaster management, Incident idempotency, and Training verification.
- **Mobile Tests (mobile/test/)**: 9 test files executing **54 tests** covering widget rendering, screen responsiveness across 6 device profiles, Arabic RTL text direction, auth validation, caching, and state transitions.
- **Automated Scripts (scripts/)**:
  - 	est-end-to-end.ps1 (15.4 KB): Full 14-stage automated integration script covering health check, registration, token rotation, RBAC enforcement, medical profile, emergency contacts, SOS creation, notification delivery, STOMP WebSocket event receipt, volunteer acceptance, EMS coordination, Smart ER ranking, status progression, and logout.
  - erify-demo.ps1 (3.3 KB): Smoke test verifying running daemon health, demo incident counts, volunteer dispatch eligibility, and Smart ER rankings.
  - uild-android-release.ps1 (3.1 KB): Builds compressed, AOT-compiled release APK (56.6 MB / 59.7 MB file).
  - iew-database.ps1: Terminal inspector for PostgreSQL relational and spatial tables.

---

## 3. Inaccessible, Missing, or Unlocated Artifacts

As required by the audit rules, the following artifacts were explicitly searched for but **were not located in the inspected workspace**:

1. **Smart_Aid_ISEF_Poster_140x120cm.pdf**:
   - **Search Status:** Not found in workspace root, docs/, scripts/, or subdirectories.
   - **Impact:** Previous physical poster claims cannot be audited from a raw PDF file; they are reconciled against the verified documentation in docs/ and inal_report.md.
2. **Prior PowerPoint Presentation (.pptx / .ppt)**:
   - **Search Status:** Not found in workspace.
   - **Impact:** Fresh 12-slide presentation generated strictly from verified repository evidence.
3. **External Clinical Validation Records**:
   - **Search Status:** No clinical trial logs, IRB/ethics approvals, or real hospital patient datasets exist in the repository.
   - **Finding:** The system is an engineering prototype and research simulation, not a clinically validated medical device.

---

*Verified and cataloged by Master Project Auditor on 2026-11-16.*
