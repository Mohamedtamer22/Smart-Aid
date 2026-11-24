<div align="center">
  <h1>SMART AID</h1>
  <h3>The Right Help. At The Right Time.</h3>
  <p><strong>Emergency Response Coordination & Healthcare Support Platform</strong></p>
  <p>
    A human-in-the-loop software prototype for emergency intake, responder coordination,
    EMS operations, and connected healthcare workflows.
  </p>
  <p>
    <img src="https://img.shields.io/badge/Java-21%2B-orange?logo=openjdk&logoColor=white" alt="Java 21+" />
    <img src="https://img.shields.io/badge/Spring%20Boot-3.5.7-6DB33F?logo=springboot&logoColor=white" alt="Spring Boot 3.5.7" />
    <img src="https://img.shields.io/badge/Flutter-Mobile%20Client-02569B?logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Angular-21-DD0031?logo=angular&logoColor=white" alt="Angular 21" />
    <img src="https://img.shields.io/badge/PostgreSQL-18-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL 18" />
    <img src="https://img.shields.io/badge/PostGIS-Geospatial-4169E1?logo=postgresql&logoColor=white" alt="PostGIS" />
    <img src="https://img.shields.io/badge/Project-Research%20Prototype-596579" alt="Research prototype" />
  </p>
</div>

> [!IMPORTANT]
> **Safety and scope:** Smart Aid is a research and software prototype for coordination and decision support. It is **not** an emergency dispatch authority, a medical device, a diagnostic system, or a substitute for national emergency numbers, licensed clinicians, or official emergency services. It does not guarantee responder availability, ambulance dispatch, hospital capacity, transport, or treatment. Demo records and resource data are fictional or locally maintained unless explicitly verified by an authorized source.

---

## Contents

- [Overview](#overview)
- [The problem](#the-problem)
- [Core capabilities](#core-capabilities)
- [Decision-support engines](#decision-support-engines)
- [System architecture](#system-architecture)
- [Technology stack](#technology-stack)
- [Repository structure](#repository-structure)
- [Getting started](#getting-started)
- [Run the applications](#run-the-applications)
- [Quality checks](#quality-checks)
- [Verification snapshot](#verification-snapshot)
- [Documentation and ISEF materials](#documentation-and-isef-materials)
- [Current limitations](#current-limitations)
- [Security principles](#security-principles)
- [Contributing](#contributing)

## Overview

**Smart Aid** is a full-stack emergency-response coordination and healthcare-support prototype. It brings several stages of an emergency workflow into one connected platform: a citizen can submit a manual SOS request, authorized responders can review and accept eligible incidents, and EMS personnel can manage incident progress and inspect explainable hospital recommendations.

The system includes a Flutter mobile client, an Angular web command center and organization portals, a Spring Boot backend, and a PostgreSQL database with PostGIS spatial support. The design emphasizes clear incident status, role-based access, auditable actions, geospatial awareness, and human oversight of operational decisions.

Smart Aid is developed by **Team FirstLine** as a software-systems project. Its guiding principle is simple: technology can help people coordinate information and resources, while emergency and clinical decisions remain with authorized humans.

## The problem

During an emergency, useful information can be fragmented across callers, responders, dispatch teams, and healthcare facilities. Delays can occur when incident details, location, responder eligibility, and destination considerations are difficult to coordinate.

Smart Aid explores a software workflow for organizing these activities:

1. Capture a manually initiated emergency request and its reported location.
2. Structure user-reported indicators into a non-diagnostic priority suggestion.
3. Identify eligible nearby responders using configurable operational criteria.
4. Give EMS personnel an incident-management view and transparent destination recommendations.
5. Preserve status changes and sensitive actions in an auditable system record.

The prototype evaluates software workflows and algorithms using controlled local data. It does not claim a measured reduction in real-world response time or clinically validated triage accuracy.

## Core capabilities

### 1. Citizen mobile experience

- Manual SOS initiation with location capture and server confirmation.
- Incident history, details, and status timeline.
- Optional structured emergency check-in using user-reported information.
- Personal medical profile and emergency-contact management, with consent-aware access rules.
- In-app notification inbox and incident updates.
- English and Arabic localization, including right-to-left Arabic layouts.
- Offline safety content and a local request queue that can synchronize after connectivity returns. **An offline request cannot alert responders until the device reconnects.**

### 2. Volunteer and first-responder workspace

- Volunteer readiness, availability, skills, and location updates.
- Nearby incident visibility subject to server-side eligibility rules.
- Dispatch ranking that considers operational fit, including location, estimated travel, skills, certification status, and availability.
- Concurrency-safe mission acceptance and auditable mission-status progression.
- Multi-responder task coordination for specialized response roles.
- Training modules and quizzes. Any completion record is an internal application record, not an externally accredited qualification.

### 3. EMS Emergency Command Center

- Centralized incident queue and incident lifecycle management.
- Authorized status transitions and an auditable incident timeline.
- Volunteer and ambulance coordination views.
- Explainable Smart ER hospital comparisons, including the factors contributing to each recommendation.
- Human confirmation or override of a suggested destination.
- Medical handover workflow between authorized operational roles.
- Disaster-management and resource-overview workflows backed by the platform's configured data.

### 4. Web portals and connected healthcare workflows

The Angular web application provides the Emergency Command Center and organization-oriented portal surfaces. The repository also contains workflow modules for healthcare resources and services, including hospitals, AED devices, pharmacies, laboratories, blood banks, medical providers, and medical delivery.

These modules have different levels of integration maturity. Local records and seeded demonstration fixtures are not equivalent to live operational feeds from hospitals, pharmacies, laboratories, blood banks, or delivery providers. External provider connectivity must be configured and independently verified before any real-world use.

### 5. Security, identity, and traceability

- Password hashing and JWT-based authentication.
- Refresh-token rotation and secure token storage in the mobile client.
- Server-side role-based access control (RBAC); client-supplied role claims are not trusted.
- User-owned data scoping for personal records and incident access.
- Auditable records for important incident and sensitive-data actions.
- Authenticated STOMP/WebSocket communication for supported real-time updates.

## Decision-support engines

Smart Aid uses transparent, deterministic logic in its current prototype. These components are designed to support human workflows, not replace professional judgment.

| Component | What it does | Important boundary |
|---|---|---|
| **Structured triage** | Applies documented rules to user-reported emergency indicators and suggests a priority category. | Rule-based decision support only; it is not an AI/ML diagnostic model and has no clinically validated accuracy claim. |
| **Smart Dispatch** | Filters and ranks eligible volunteers using operational factors such as proximity, estimated travel, skills, certification validity, and availability. | Ranking depends on the quality and freshness of locally available responder data; it does not guarantee that a responder will accept or arrive. |
| **Smart ER** | Scores eligible hospital candidates using estimated travel time, critical-care capability, specialty alignment, and reported congestion. | Hospital capacity and congestion are based on stored/local data in the prototype, not verified live feeds. EMS personnel retain destination authority. |

### Smart ER scoring model

The current documented weighting is:

| Factor | Weight |
|---|---:|
| Estimated travel-time score | 30% |
| Critical-care capability | 30% |
| Specialty alignment | 25% |
| Reported congestion | 15% |
| **Total** | **100%** |

Each recommendation is accompanied by human-readable factors so an authorized operator can understand and, where appropriate, override the suggested ranking. Travel estimates are model-based estimates, not live traffic measurements or guaranteed arrival times.

## System architecture

```mermaid
flowchart TD
    subgraph Clients[User-facing applications]
        Mobile[Flutter mobile client\nCitizen · Volunteer · EMS]
        Web[Angular web application\nEmergency Command Center · Portals]
    end

    Mobile -->|REST over HTTP(S)\nAuthenticated STOMP/WebSocket| API
    Web -->|REST over HTTP(S)| API

    subgraph Backend[Spring Boot modular backend]
        API[Spring Boot API]
        Security[Authentication · JWT · RBAC]
        Incidents[Incident intake · Lifecycle · Audit]
        Dispatch[Structured triage · Smart Dispatch]
        SmartER[Smart ER · EMS workflows]
        Healthcare[Resources · Training · Healthcare modules]
        API --- Security
        API --- Incidents
        API --- Dispatch
        API --- SmartER
        API --- Healthcare
    end

    API -->|JPA / SQL| DB[(PostgreSQL 18\n+ PostGIS)]
    Migrations[Flyway migrations V1–V8] --> DB
```

The backend is organized as a **modular monolith**. PostgreSQL is the system of record, PostGIS provides geospatial data support, and Flyway manages schema evolution. The clients communicate with the backend API; they do not connect directly to the database.

The supported development setup is native on a single Windows machine. Docker and container orchestration are not required by the current setup guide.

## Technology stack

| Layer | Technologies |
|---|---|
| **Mobile** | Flutter, Dart, Riverpod, Dio, Flutter Secure Storage, Geolocator, Flutter Map, STOMP/WebSocket client |
| **Web** | Angular 21, TypeScript, RxJS |
| **Backend** | Java 21 runtime, Spring Boot 3.5.7, Spring Security, Spring Data JPA, Bean Validation, Spring WebSocket/STOMP, Actuator, Springdoc OpenAPI |
| **Database** | PostgreSQL 18, PostGIS, Flyway migrations (V1–V8) |
| **Build and tooling** | Maven Wrapper, Flutter tooling, npm, PowerShell scripts, Git, Git LFS |

## Repository structure

```text
Smart-Aid/
├── backend/                    # Spring Boot API and domain services
├── mobile/                     # Flutter mobile application
├── web-dashboard/              # Angular command center and portals
├── database/                   # Native PostgreSQL bootstrap scripts
├── scripts/                    # Windows setup, launch, build, and test helpers
├── docs/                       # Architecture, API, security, UX, and runbooks
├── Smart_Aid_ISEF_Submission/   # Research, audit, abstract, poster, and presentation files
├── final_report.md             # Detailed project report
├── .env.example                # Local environment template
└── README.md
```

## Getting started

The following instructions describe the repository's native Windows development setup.

### Prerequisites

Install the tools relevant to the applications you plan to run:

- **Git** and **Git LFS** (required for large tracked objects in this repository).
- **Java 21 or later** for the backend runtime.
- **PostgreSQL 18** with the **PostGIS** extension.
- **Flutter SDK** and **Android Studio / Android SDK** for the mobile client.
- **Node.js and npm** for the Angular web application.
- Windows PowerShell for the supplied `.ps1` helper scripts.

> The repository contains large Git LFS objects, including generated build-related content. Allow several gigabytes of free disk space when cloning the full repository.

### 1. Clone the repository

```powershell
git lfs install
git clone https://github.com/Mohamedtamer22/Smart-Aid.git
cd Smart-Aid
```

### 2. Create the local database

1. Open `database/bootstrap.sql`.
2. Replace the placeholder database password with a strong, unique local password.
3. Run the script in pgAdmin's Query Tool while connected as a PostgreSQL administrator.
4. Keep the password for the local environment configuration step below.

The bootstrap script creates the local `smartaid` database and `smartaid_user`, then enables PostGIS and `pgcrypto`. The backend applies the versioned schema migrations through Flyway when it starts.

### 3. Configure local environment variables

Copy the example file:

```powershell
Copy-Item .env.example .env
```

Edit `.env` and set at least:

- `DB_PASSWORD` — the same password used in `database/bootstrap.sql`.
- `JWT_SECRET` — a strong random secret of at least 32 bytes.

Keep `.env` local. It is intentionally excluded from version control. Values such as `MAP_API_KEY`, `NOTIFICATION_API_KEY`, and `AI_API_KEY` in `.env.example` are placeholders; they do not mean that an external provider integration is already active.

### 4. Start the backend

Open a PowerShell window at the repository root:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

The API runs on `http://localhost:8080` by default.

- Health check: `http://localhost:8080/actuator/health`
- Interactive API documentation: `http://localhost:8080/swagger-ui/index.html`

### 5. Run the Flutter mobile application

Open a second terminal:

```powershell
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` is the Android emulator's route to the host computer. For Windows desktop, Chrome, or a local iOS simulator, use `http://localhost:8080`. For a physical device, configure the computer's trusted LAN address and the corresponding allowed origin in `.env`; do not expose the development API directly to the public internet.

### 6. Run the Angular web application

Open another terminal:

```powershell
cd web-dashboard
npm install
npm start
```

Then open `http://localhost:4200`. Keep the backend running while using API-connected portal features.

### Optional: start the fictional demo scenario

After PostgreSQL and `.env` are configured, the helper below can start the local API with the opt-in fictional presentation seed:

```powershell
cd ..
.\scripts\start-demo.ps1
```

This script enables `SMARTAID_DEMO_SEED` for the launched process. Demo accounts, incidents, and resource records are fictional local fixtures; they must never be presented as live emergency-service data.

## Quality checks

Run the checks from the relevant project directory.

**Backend tests**

```powershell
cd backend
.\mvnw.cmd test
```

**Flutter analysis and tests**

```powershell
cd mobile
flutter analyze
flutter test
```

**Angular tests and production build**

```powershell
cd web-dashboard
npm test -- --watch=false
npm run build
```

**Four-tier E2E harness dry run** (from the repository root)

```powershell
.\scripts\test-e2e-all-tiers.ps1 -DryRun
```

A dry run validates the harness path; it is not equivalent to a live end-to-end run against a fully provisioned environment.

## Verification snapshot

The following results are recorded in the repository's **V2 implementation verification report dated 2026-11-18**:

| Area | Recorded result |
|---|---:|
| Spring Boot backend tests | 35 / 35 passed |
| Flutter static analysis | 0 issues reported |
| Flutter tests | 62 / 62 passed |
| Angular production build | Build completed successfully |
| Angular unit tests | 2 / 2 passed |
| Four-tier E2E harness | 276 / 276 passed in **dry-run mode** |

These are dated verification results, not a guarantee that every environment will reproduce them unchanged. The 276-stage harness result was a dry run; the report explicitly distinguishes it from a live execution of the full suite against the native database and backend.

## Documentation and ISEF materials

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | System components and trust boundaries |
| [Run from zero](docs/run-from-zero.md) | Detailed Windows setup guide |
| [API contract](docs/api-contract.md) | API structure and conventions |
| [Security review](docs/SECURITY_REVIEW.md) | Security and privacy review notes |
| [Smart ER](docs/smart-er.md) | Hospital recommendation logic |
| [Smart Dispatch](docs/smart-dispatch.md) | Responder ranking and eligibility logic |
| [Research plan](docs/research-plan.md) | Research framing and methodology |
| [Final report](final_report.md) | Detailed project report |
| [ISEF deliverables index](Smart_Aid_ISEF_Submission/README_Deliverables.md) | Catalog of submission materials |
| [V2 implementation verification](Smart_Aid_ISEF_Submission/Implementation_Verification_Report_V2.md) | Feature and test verification snapshot |
| [Presentation deck (PPTX)](Smart_Aid_ISEF_Submission/PowerPoint_Smart_Aid.pptx) | Project presentation |
| [Presentation deck (PDF)](Smart_Aid_ISEF_Submission/PowerPoint_Smart_Aid.pdf) | PDF presentation export |
| [Research abstract](Smart_Aid_ISEF_Submission/Abstract_Smart_Aid.txt) | Plain-text abstract |

## Current limitations

Smart Aid is a controlled prototype, not a production emergency-response service. The following boundaries are important:

- **No official emergency dispatch integration:** the prototype does not directly dispatch national EMS, police, fire, or other official emergency services.
- **No live provider feeds by default:** hospital capacity, congestion, AED, pharmacy, laboratory, blood-bank, medical-provider, and delivery data may be local or seeded demonstration records.
- **No autonomous medical diagnosis:** triage is deterministic and rule-based. It has not been clinically validated as a diagnostic or treatment system.
- **No guaranteed route or ETA:** travel times are estimates and do not represent verified live road conditions.
- **Offline behavior is limited:** offline guides and queued requests can be stored locally, but an emergency request cannot reach responders until connectivity is restored.
- **No production deployment claim:** real-world use would require security hardening, privacy and regulatory review, clinical governance, verified data sources, operational agreements, and supervised field evaluation.

## Security principles

- Never commit `.env`, passwords, JWT secrets, API keys, tokens, or private credentials.
- Use fictional data for demos and automated tests. Do not store real patient or emergency records in the repository.
- Restrict development access to trusted local devices and networks.
- Use HTTPS and production-grade secret management before any deployment beyond local development.
- Treat all recommendations and status dashboards as decision-support tools requiring authorized human oversight.

## Contributing

Contributions should preserve the project's safety boundaries and evidence-based documentation. For a change:

1. Create a focused branch from the current default branch.
2. Keep secrets and real personal or medical data out of commits.
3. Add or update tests for the affected workflow.
4. Update the relevant API, architecture, and verification documentation.
5. Run the backend, mobile, and/or web checks affected by the change before opening a pull request.

---

<div align="center">
  <strong>SMART AID</strong><br />
  <em>The Right Help. At The Right Time.</em><br />
  Built by Team FirstLine
</div>
