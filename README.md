# Smart Aid

Smart Aid is a native, single-machine emergency-response coordination and decision-support platform. It is **not** a substitute for official emergency services, clinical judgment, diagnosis, or guaranteed hospital capacity.

> This project runs natively on one development machine without Docker.

## Implemented vertical slice

- Spring Boot API foundation with JWT access/refresh-token rotation, password hashing, RBAC, validation, safe errors, audit events, OpenAPI, and local WebSocket topics.
- PostgreSQL/PostGIS Flyway schema for users, incidents, volunteers, hospitals, ambulances, AEDs, training, notifications, and audit history.
- Manual SOS creation with server confirmation, auditable incident state transitions, rule-based dispatch ranking, explainable Smart ER ranking, and an atomic volunteer-acceptance workflow.
- Flutter Riverpod/Dio app with English/Arabic localization, persisted language choice, secure token storage, a refined SOS/check-in/location flow, incident timeline, medical profile, emergency contacts, notification inbox, volunteer readiness/mission dashboard, EMS operations dashboard, and explainable Smart ER comparison screen.

Other domain modules are schema-ready or documented as planned; they must not be treated as operational emergency-service integrations. See [docs/current-state.md](docs/current-state.md), [docs/architecture.md](docs/architecture.md), and [docs/developer-guide.md](docs/developer-guide.md).

For a copy-and-run Windows setup with exact commands, see [docs/run-from-zero.md](docs/run-from-zero.md).

## Native local setup (Windows)

1. Install Java 21+ (the checked environment uses Java 21), Flutter, Android Studio/SDK, PostgreSQL, and the PostGIS extension. Maven is supplied through the committed Maven Wrapper, so a separate global Maven installation is not required. No container runtime is needed.
2. In PostgreSQL's native `psql` or pgAdmin Query Tool, run [database/bootstrap.sql](database/bootstrap.sql) as an administrator. It creates the `smartaid` database and `smartaid_user`; amend the password first.
3. Copy `.env.example` to `.env` and set the matching database password plus a strong random `JWT_SECRET` (32+ bytes). The backend reads this local file; do not commit it.
4. Start the API:

   ```powershell
   cd backend
   .\mvnw.cmd spring-boot:run
   ```

   API: `http://localhost:8080` · OpenAPI UI: `http://localhost:8080/swagger-ui/index.html` · health: `http://localhost:8080/actuator/health`

   If Java 25 is used on Windows, set `SMARTAID_TOMCAT_NIO2=true` in `.env` for the local selector compatibility switch; Java 21–24 do not require it.

5. Start Flutter:

   ```powershell
   cd mobile
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
   ```

   `10.0.2.2` reaches the same PC from an Android emulator. For Windows/web or an iOS simulator use `http://localhost:8080`; for a physical device use a configurable LAN address and allow it in `CORS_ALLOWED_ORIGINS`.

## Verification

```powershell
cd backend; .\mvnw.cmd test
cd ..\mobile; flutter analyze; flutter test
```

Backend tests cover pure state-transition, dispatch, volunteer-mission, and Smart ER rules without a database server. Running the full API requires the native PostgreSQL/PostGIS database above.

## Presentation demo

The optional presentation scenario is fictional, local-only, and disabled by default. Set `SMARTAID_DEMO_SEED=true` in your untracked `.env`, then run:

```powershell
.\scripts\start-demo.ps1
```

It checks the native dependencies, starts the API if required, waits for the health endpoint, and seeds repeatable accounts and simulated incidents. Use [docs/demo-runbook.md](docs/demo-runbook.md) for the controlled demo flow and [docs/presentation-checklist.md](docs/presentation-checklist.md) before presenting. Do not use the scenario to represent live emergency-service data.

Verify the ready scenario without changing its incidents:

```powershell
.\scripts\verify-demo.ps1
```

Run the complete local quality gate—backend tests, Flutter analysis/tests, and the live fictional scenario check—with:

```powershell
.\scripts\verify-all.ps1
```

The launcher and verification scripts use Java 21+ automatically. If more than one JDK is installed, set `SMARTAID_JAVA_HOME` in the local `.env` to choose the backend JDK explicitly.

Build a locally installable Android debug APK with:

```powershell
.\scripts\build-android-debug.ps1
```

The script keeps Flutter's required Android Gradle build native, but selects a Windows-safe temporary directory for the build process only.

Run the stateful local end-to-end workflow (registration → confirmed SOS → volunteer → EMS → Smart ER → resolved case) with:

```powershell
.\scripts\test-end-to-end.ps1
```

It creates uniquely tagged fictional local test data and leaves an auditable resolved test case; it never contacts emergency services.

If an E2E run is interrupted, cancel only its active tagged fictional records through the API before a presentation:

```powershell
.\scripts\cleanup-e2e.ps1
```

## Repository layout

- `backend/` — Spring Boot modular monolith/API
- `mobile/` — Flutter mobile client
- `database/` — native PostgreSQL bootstrap and seed policy
- `docs/` — implementation-matched engineering, API, security, UX, and research notes
- `scripts/` — non-container local helpers

Never commit credentials, tokens, real medical data, real emergency resource availability, or provider keys.
