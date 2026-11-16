# Smart Aid — API Endpoint Inventory & Interface Specification

**Project:** Smart Aid  
**Audit Date:** 2026-11-16  
**Auditor:** Backend Systems Auditor & API Architect  
**Backend Framework:** Spring Boot 3.5.7 with Spring MVC & Spring Security 6  
**Total Mapped Controller Handlers:** **63 Methods**  
**Total Unique (Method, Path) Endpoints:** **58 Endpoints**  
**Real-Time & Monitoring Endpoints:** 1 STOMP WebSocket Broker (`/ws`), 2 Spring Boot Actuator Endpoints (`/actuator/health`, `/actuator/info`)

---

## 1. Summary by Domain Controller

| Domain Group | Controller Name | Base Path | Handler Count | Primary Roles Allowed |
| :--- | :--- | :--- | :---: | :--- |
| **Authentication** | `AuthController.java` | `/api/auth` | 4 | Public (with Rate Limiting on login/register) |
| **User Identity** | `UserController.java` | `/api/users` | 1 | Any Authenticated User |
| **Hospital Partner** | `HospitalPartnerController.java` | `/api/hospital-partner` | 1 | `ROLE_HOSPITAL` |
| **Incident Management** | `IncidentController.java` | `/api/incidents` | 7 | `ROLE_USER`, `ROLE_VOLUNTEER`, `ROLE_EMS`, `ROLE_ADMIN` |
| **Volunteer Operations** | `VolunteerController.java` | `/api/volunteers` | 9 | `ROLE_VOLUNTEER`, Authenticated |
| **Smart Dispatch** | `SmartDispatchController.java` | `/api/smart-dispatch` | 1 | `ROLE_EMS`, `ROLE_ADMIN` |
| **EMS Operations** | `EmsController.java` | `/api/ems` | 3 | `ROLE_EMS`, `ROLE_ADMIN` |
| **Smart ER Engine** | `SmartErController.java` | `/api/smart-er` | 2 | `ROLE_EMS`, `ROLE_ADMIN` |
| **Hospital Directory** | `HospitalController.java` | `/api/hospitals` | 2 | Public / EMS / Admin |
| **AED & Resources** | `AedController.java` | `/api/aed-devices` | 3 | Public, `ROLE_EMS`, `ROLE_ADMIN` |
| **Ambulance Fleet** | `AmbulanceController.java` | `/api/ambulances` | 4 | Authenticated, `ROLE_EMS`, `ROLE_ADMIN` |
| **Disaster Management**| `DisasterController.java` | `/api/disaster` | 5 | `ROLE_EMS`, `ROLE_ADMIN`, `ROLE_VOLUNTEER` |
| **Training Academy** | `TrainingController.java` | `/api/training` | 3 | Any Authenticated User |
| **Medical Profile** | `ProfileController.java` | `/api/medical-profile`, `/api/emergency-contacts` | 6 | Any Authenticated User (Own records only) |
| **Notifications** | `NotificationController.java` | `/api/notifications` | 2 | Any Authenticated User (Own records only) |
| **Executive Analytics** | `AnalyticsController.java` | `/api/analytics` | 2 | `ROLE_EMS`, `ROLE_ADMIN`, `ROLE_VOLUNTEER` |
| **System Administration**| `AdminController.java` | `/api/admin` | 8 | `ROLE_ADMIN` |
| **Total** | **17 Controllers** | — | **63** | — |

---

## 2. Complete Exhaustive Endpoint Specification Table

| # | HTTP Method | Path | Controller Handler | Purpose & Description | Required Role / Auth | Request Body DTO | Response Body DTO | Tested in E2E / Unit | Status |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| 1 | `POST` | `/api/auth/register` | `AuthController.register()` | Register citizen, volunteer, or hospital user | Public (Rate Limited) | `AuthDtos.RegisterRequest` | `AuthDtos.TokenResponse` | E2E Stage 3 | **VERIFIED** |
| 2 | `POST` | `/api/auth/login` | `AuthController.login()` | Authenticate user & issue JWT + Refresh Token | Public (Rate Limited) | `AuthDtos.LoginRequest` | `AuthDtos.TokenResponse` | E2E Stage 1 | **VERIFIED** |
| 3 | `POST` | `/api/auth/refresh` | `AuthController.refresh()` | Rotate refresh token & issue new JWT pair | Public | `AuthDtos.RefreshRequest` | `AuthDtos.TokenResponse` | E2E Stage 5 | **VERIFIED** |
| 4 | `POST` | `/api/auth/logout` | `AuthController.logout()` | Invalidate & revoke active refresh token session | Public / Authenticated | `AuthDtos.RefreshRequest` | `204 No Content` | E2E Stage 14 | **VERIFIED** |
| 5 | `GET` | `/api/users/me` | `UserController.current()` | Retrieve currently authenticated user profile | Authenticated | None | `AuthDtos.UserResponse` | E2E Stage 2 | **VERIFIED** |
| 6 | `GET` | `/api/hospital-partner/me` | `HospitalPartnerController.current()` | Check onboarding status of hospital partner applicant | `ROLE_HOSPITAL` | None | `HospitalPartnerStatusResponse` | Unit Test | **VERIFIED** |
| 7 | `POST` | `/api/incidents` | `IncidentController.create()` | Create emergency incident with `Idempotency-Key` | Authenticated (`ROLE_USER`) | `CreateIncidentRequest` | `IncidentResponse` | E2E Stage 10 | **VERIFIED** |
| 8 | `GET` | `/api/incidents/mine` | `IncidentController.mine()` | List authenticated citizen's historical incidents | Authenticated (`ROLE_USER`) | None | `List<IncidentResponse>` | Mobile App | **VERIFIED** |
| 9 | `GET` | `/api/incidents/my` | `IncidentController.my()` | Compatibility alias for `/api/incidents/mine` | Authenticated (`ROLE_USER`) | None | `List<IncidentResponse>` | Unit Test | **VERIFIED** |
| 10 | `GET` | `/api/incidents/{id}` | `IncidentController.detail()` | Get incident details and immutable status timeline | Reporter / EMS / Admin | None | `IncidentDetailResponse` | E2E Stage 10 | **VERIFIED** |
| 11 | `PATCH` | `/api/incidents/{id}/status` | `IncidentController.changeStatus()` | Transition incident state in state machine | Reporter (Cancel) / EMS / Admin | `ChangeStatusRequest` | `IncidentResponse` | E2E Stage 13 | **VERIFIED** |
| 12 | `POST` | `/api/incidents/{id}/status` | `IncidentController.postStatus()` | POST compatibility alias for status transition | Reporter (Cancel) / EMS / Admin | `ChangeStatusRequest` | `IncidentResponse` | Mobile App | **VERIFIED** |
| 13 | `POST` | `/api/incidents/{id}/accept` | `IncidentController.accept()` | Compatibility route for volunteer acceptance | `ROLE_VOLUNTEER` | None | `MissionResponse` | Mobile App | **VERIFIED** |
| 14 | `POST` | `/api/volunteers/me/onboarding` | `VolunteerController.startOnboarding()` | Initialize unverified volunteer profile | Authenticated | None | `VolunteerProfileResponse` | Unit Test | **VERIFIED** |
| 15 | `GET` | `/api/volunteers/me` | `VolunteerController.profile()` | Retrieve volunteer readiness, location & skills | `ROLE_VOLUNTEER` | None | `VolunteerProfileResponse` | E2E Stage 12 | **VERIFIED** |
| 16 | `PUT` | `/api/volunteers/me/availability` | `VolunteerController.updateAvailability()` | Toggle volunteer availability (`available=true/false`) | `ROLE_VOLUNTEER` | Boolean payload | `VolunteerProfileResponse` | Mobile App | **VERIFIED** |
| 17 | `PUT` | `/api/volunteers/me/location` | `VolunteerController.updateLocation()` | Update volunteer GPS coordinates in PostGIS | `ROLE_VOLUNTEER` | `Coordinates` | `VolunteerProfileResponse` | Mobile App | **VERIFIED** |
| 18 | `GET` | `/api/volunteers/dashboard` | `VolunteerController.dashboard()` | Get readiness, active mission & nearby incident count | `ROLE_VOLUNTEER` | None | `VolunteerDashboardResponse` | Mobile App | **VERIFIED** |
| 19 | `GET` | `/api/volunteers/incidents/nearby` | `VolunteerController.nearbyIncidents()` | Spatial search for searching incidents within 15 km | `ROLE_VOLUNTEER` | None | `List<NearbyIncidentResponse>` | E2E Stage 12 | **VERIFIED** |
| 20 | `POST` | `/api/volunteers/incidents/{incidentId}/accept` | `VolunteerController.accept()` | Concurrency-safe volunteer mission acceptance (`FOR UPDATE`) | `ROLE_VOLUNTEER` | None | `MissionResponse` | E2E Stage 12 | **VERIFIED** |
| 21 | `GET` | `/api/volunteers/missions/active` | `VolunteerController.activeMission()` | Retrieve active accepted volunteer emergency mission | `ROLE_VOLUNTEER` | None | `MissionResponse` | E2E Stage 12 | **VERIFIED** |
| 22 | `PATCH` | `/api/volunteers/missions/{missionId}` | `VolunteerController.updateMission()` | Update volunteer status (`ARRIVED` or `COMPLETED`) | `ROLE_VOLUNTEER` (Owner) | Status payload | `MissionResponse` | E2E Stage 12 | **VERIFIED** |
| 23 | `GET` | `/api/smart-dispatch/incidents/{incidentId}/recommendations` | `SmartDispatchController.recommendations()` | Multi-factor volunteer ranking (Distance, ETA, Skills) | `ROLE_EMS`, `ROLE_ADMIN` | None | `List<DispatchRecommendation>` | Unit Test | **VERIFIED** |
| 24 | `GET` | `/api/ems/dashboard` | `EmsController.dashboard()` | Operations overview: active/critical incidents, ambulances | `ROLE_EMS`, `ROLE_ADMIN` | None | `EmsDtos.DashboardResponse` | E2E Stage 13 | **VERIFIED** |
| 25 | `GET` | `/api/ems/incidents/{incidentId}` | `EmsController.incident()` | EMS incident detail with timeline and notes | `ROLE_EMS`, `ROLE_ADMIN` | None | `EmsDtos.IncidentDetail` | Smoke Test | **VERIFIED** |
| 26 | `POST` | `/api/ems/incidents/{incidentId}/assign` | `EmsController.assign()` | Begin EMS coordination on active incident | `ROLE_EMS`, `ROLE_ADMIN` | None | `EmsDtos.AssignResponse` | E2E Stage 13 | **VERIFIED** |
| 27 | `GET` | `/api/smart-er/incidents/{incidentId}/recommendations` | `SmartErController.recommendations()` | Smart ER multi-factor hospital destination ranking | `ROLE_EMS`, `ROLE_ADMIN` | None | `List<HospitalRecommendation>` | E2E Stage 13 | **VERIFIED** |
| 28 | `GET` | `/api/smart-er/{incidentId}` | `SmartErController.recommendationsAlias()` | Compatibility route for Smart ER recommendations | `ROLE_EMS`, `ROLE_ADMIN` | None | `List<HospitalRecommendation>` | Mobile App | **VERIFIED** |
| 29 | `GET` | `/api/hospitals` | `HospitalController.verifiedHospitals()` | Directory of all verified participating hospitals | Public / Authenticated | None | `List<HospitalResponse>` | Mobile App | **VERIFIED** |
| 30 | `GET` | `/api/hospitals/recommendation/{incidentId}` | `HospitalController.recommendation()` | Compatibility route for hospital recommendation | Public / Authenticated | None | `List<HospitalRecommendation>` | Unit Test | **VERIFIED** |
| 31 | `GET` | `/api/aed-devices` | `AedController.list()` | Directory of verified AEDs and emergency equipment | Public / Authenticated | None | `List<AedResponse>` | Mobile App | **VERIFIED** |
| 32 | `GET` | `/api/aed-devices/nearby` | `AedController.nearby()` | Spatial search for AEDs within radius of coordinates | Public / Authenticated | Coordinates params | `List<AedResponse>` | Unit Test | **VERIFIED** |
| 33 | `POST` | `/api/aed-devices` | `AedController.create()` | Register new approved AED device | `ROLE_ADMIN`, `ROLE_EMS` | `CreateAedRequest` | `AedResponse` | Unit Test | **VERIFIED** |
| 34 | `GET` | `/api/ambulances` | `AmbulanceController.list()` | Fleet directory with real-time operational status pills | Authenticated | None | `List<AmbulanceResponse>` | Mobile App | **VERIFIED** |
| 35 | `GET` | `/api/ambulances/available` | `AmbulanceController.available()` | Filter for currently available ambulance units | Authenticated | None | `List<AmbulanceResponse>` | Unit Test | **VERIFIED** |
| 36 | `POST` | `/api/ambulances` | `AmbulanceController.create()` | Commission new ambulance unit into fleet | `ROLE_EMS`, `ROLE_ADMIN` | `CreateAmbulanceRequest` | `AmbulanceResponse` | Unit Test | **VERIFIED** |
| 37 | `PATCH` | `/api/ambulances/{id}/status` | `AmbulanceController.updateStatus()` | Update ambulance status (`AVAILABLE`, `EN_ROUTE`, etc.) | `ROLE_EMS`, `ROLE_ADMIN` | Status payload | `AmbulanceResponse` | Mobile App | **VERIFIED** |
| 38 | `GET` | `/api/disaster/status` | `DisasterController.status()` | Check whether mass-casualty disaster mode is active | Public / Authenticated | None | `DisasterStatusResponse` | Mobile App | **VERIFIED** |
| 39 | `GET` | `/api/disaster/overview` | `DisasterController.overview()` | Overview of disaster zones and casualty counts | `ROLE_EMS`, `ADMIN`, `VOLUNTEER` | None | `DisasterOverviewResponse` | Mobile App | **VERIFIED** |
| 40 | `POST` | `/api/disaster/activate` | `DisasterController.activate()` | Escalate system into mass-casualty disaster mode | `ROLE_EMS`, `ROLE_ADMIN` | `ActivateDisasterRequest` | `DisasterStatusResponse` | Unit Test | **VERIFIED** |
| 41 | `POST` | `/api/disaster/deactivate` | `DisasterController.deactivate()` | De-escalate system from disaster mode | `ROLE_EMS`, `ROLE_ADMIN` | None | `DisasterStatusResponse` | Unit Test | **VERIFIED** |
| 42 | `PATCH` | `/api/disaster/incidents/{incidentId}/triage` | `DisasterController.updateTriage()` | Update field triage assessment in disaster mode | `ROLE_EMS`, `ADMIN`, `VOLUNTEER` | `DisasterTriageRequest` | `IncidentResponse` | Unit Test | **VERIFIED** |
| 43 | `GET` | `/api/training/courses` | `TrainingController.courses()` | List healthcare training courses and user progress | Authenticated | None | `List<CourseSummaryResponse>` | Mobile App | **VERIFIED** |
| 44 | `GET` | `/api/training/courses/{id}` | `TrainingController.courseDetail()` | Get course curriculum, lessons, and quiz questions | Authenticated | None | `CourseDetailResponse` | Mobile App | **VERIFIED** |
| 45 | `POST` | `/api/training/courses/{id}/quiz` | `TrainingController.submitQuiz()` | Submit quiz answers; validates >= 80% passing grade | Authenticated | `QuizSubmissionRequest` | `QuizResultResponse` | Unit Test | **VERIFIED** |
| 46 | `GET` | `/api/medical-profile` | `ProfileController.medical()` | Get patient emergency profile (blood type, allergies) | Authenticated (Own profile) | None | `MedicalProfileResponse` | E2E Stage 8 | **VERIFIED** |
| 47 | `PUT` | `/api/medical-profile` | `ProfileController.updateMedical()` | Update patient emergency profile with consent toggle | Authenticated (Own profile) | `MedicalProfileRequest` | `MedicalProfileResponse` | E2E Stage 8 | **VERIFIED** |
| 48 | `GET` | `/api/emergency-contacts` | `ProfileController.contacts()` | List user's primary and secondary emergency contacts | Authenticated (Own contacts) | None | `List<ContactResponse>` | E2E Stage 9 | **VERIFIED** |
| 49 | `POST` | `/api/emergency-contacts` | `ProfileController.createContact()` | Add an emergency contact | Authenticated (Own contacts) | `ContactRequest` | `ContactResponse` | E2E Stage 9 | **VERIFIED** |
| 50 | `PUT` | `/api/emergency-contacts/{id}` | `ProfileController.updateContact()` | Modify an emergency contact | Authenticated (Own contacts) | `ContactRequest` | `ContactResponse` | E2E Stage 9 | **VERIFIED** |
| 51 | `DELETE` | `/api/emergency-contacts/{id}` | `ProfileController.deleteContact()` | Delete an emergency contact | Authenticated (Own contacts) | None | `204 No Content` | E2E Stage 9 | **VERIFIED** |
| 52 | `GET` | `/api/notifications` | `NotificationController.list()` | Retrieve user's recent notifications (limit 100) | Authenticated (Own notifications) | None | `List<NotificationResponse>` | E2E Stage 11 | **VERIFIED** |
| 53 | `PATCH` | `/api/notifications/{id}/read` | `NotificationController.markRead()` | Mark notification as read | Authenticated (Own notifications) | None | `NotificationResponse` | E2E Stage 11 | **VERIFIED** |
| 54 | `GET` | `/api/analytics/dashboard` | `AnalyticsController.dashboard()` | Executive metrics: total, active, resolved, categories | `ROLE_EMS`, `ADMIN`, `VOLUNTEER` | None | `DashboardOverview` | Unit Test | **VERIFIED** |
| 55 | `GET` | `/api/analytics/research/smart-er-comparison` | `AnalyticsController.researchComparison()` | Empirical 3-way research benchmark (Nearest vs Random vs Smart ER) | `ROLE_EMS`, `ROLE_ADMIN` | None | `ResearchReport` | E2E Stage 13 | **VERIFIED** |
| 56 | `GET` | `/api/admin/overview` | `AdminController.overview()` | Executive system overview and KPI counts | `ROLE_ADMIN` | None | `SystemOverviewResponse` | Mobile App | **VERIFIED** |
| 57 | `GET` | `/api/admin/users` | `AdminController.users()` | List registered user roster and assigned roles | `ROLE_ADMIN` | None | `List<UserSummaryResponse>` | Mobile App | **VERIFIED** |
| 58 | `PATCH` | `/api/admin/users/{id}/roles` | `AdminController.updateRoles()` | Assign or revoke roles for a user account | `ROLE_ADMIN` | Roles list | `UserSummaryResponse` | Unit Test | **VERIFIED** |
| 59 | `PATCH` | `/api/admin/users/{id}/status` | `AdminController.updateStatus()` | Enable or disable user account access | `ROLE_ADMIN` | Status boolean | `UserSummaryResponse` | Mobile App | **VERIFIED** |
| 60 | `GET` | `/api/admin/volunteers` | `AdminController.volunteers()` | View volunteer verification and credential queue | `ROLE_ADMIN` | None | `List<VolunteerSummary>` | Mobile App | **VERIFIED** |
| 61 | `POST` | `/api/admin/volunteers/{id}/verify` | `AdminController.verifyVolunteer()` | Verify and credential a volunteer profile | `ROLE_ADMIN` | None | `200 OK` | Mobile App | **VERIFIED** |
| 62 | `POST` | `/api/admin/hospitals` | `AdminController.createHospital()` | Create and verify a hospital partner record | `ROLE_ADMIN` | Hospital details | `HospitalResponse` | Mobile App | **VERIFIED** |
| 63 | `GET` | `/api/admin/audit-logs` | `AdminController.auditLogs()` | Inspect immutable security and medical access audit trail | `ROLE_ADMIN` | None | `List<AuditLogEntry>` | Mobile App | **VERIFIED** |

---

## 3. Real-Time WebSocket & Monitoring Endpoints

- **`WS /ws` (Handshake Endpoint):** Authenticated STOMP handshake validating JWT Bearer token in the `CONNECT` frame via `StompAuthChannelInterceptor.java`.
- **`/topic/incidents/{incidentId}` (Incident Tracking Channel):** Real-time broadcast channel delivering state-machine transitions and responder arrival events directly to the patient's phone and EMS console.
- **`GET /actuator/health` & `GET /actuator/info`:** Production health check endpoints returning database connectivity status and service readiness (`{"status": "UP"}`).

---

*Compiled from Java AST Source Code Analysis by Master Systems Auditor on 2026-11-16.*
