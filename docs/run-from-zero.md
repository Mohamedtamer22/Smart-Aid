# Run Smart Aid from zero on Windows

Smart Aid runs natively on one computer. It does not use Docker, Docker Compose, a VM, or containerized services.

## 1. Install the native prerequisites

Install these once:

- Java 21 LTS (the backend is compiled for Java 21)
- Flutter SDK and Android Studio with the Android SDK
- PostgreSQL 18 with the PostGIS extension
- Git

Open a fresh PowerShell window in the project root and confirm Flutter's Android toolchain:

```powershell
flutter doctor
```

Install any Android SDK licenses or components reported by `flutter doctor` before continuing.

## 2. Create the local database

1. Open [database/bootstrap.sql](../database/bootstrap.sql).
2. Replace `replace-with-a-long-unique-database-password` with a new local-only password.
3. In **pgAdmin Query Tool** while connected as the PostgreSQL administrator, run the entire script.

It creates the `smartaid` database, the `smartaid_user` local account, PostGIS, and `pgcrypto`. Do not commit the chosen password.

## 3. Configure the local environment

```powershell
Copy-Item .env.example .env
```

Edit `.env` and set:

- `DB_PASSWORD` to the same password used in `bootstrap.sql`
- `JWT_SECRET` to a random value of at least 32 bytes
- `SMARTAID_DEMO_SEED=true` for the fictional presentation scenario

If multiple JDKs are installed, set `SMARTAID_JAVA_HOME` to the Java 21 installation. The project scripts otherwise detect a compatible JDK automatically.

## 4. Start the local stack

From the project root:

```powershell
.\scripts\start-demo.ps1
```

This checks PostgreSQL on `localhost:5432`, starts Spring Boot at `http://localhost:8080` if required, applies Flyway migrations, and creates only fictional presentation data.

Confirm the backend:

- Health: `http://localhost:8080/actuator/health`
- API documentation: `http://localhost:8080/swagger-ui/index.html`

The root URL (`http://localhost:8080/`) is intentionally protected and returns `401`; the Flutter application is the user interface.

## 5. Run the Flutter app

In a second PowerShell window:

```powershell
cd mobile
flutter pub get
```

Choose exactly one target command:

| Target | Command |
| --- | --- |
| Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` |
| Windows desktop or Chrome | `flutter run --dart-define=API_BASE_URL=http://localhost:8080` |
| Physical device | `flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8080` |

For a physical device, add the matching local origin to `CORS_ALLOWED_ORIGINS` in `.env`, keep the device on the same trusted network, and do not expose the development API to the public internet. The Android debug manifest permits local HTTP only for development; production deployment must use HTTPS.

Do not open `mobile/web/index.html` with a `file:///` URL: Flutter Web must be started with `flutter run` (or served from `mobile/build/web` after a web build). Opening the source HTML file directly produces a blank page.

## 6. Use the fictional presentation accounts

| Workspace | Email | Password |
| --- | --- | --- |
| Citizen experience | `demo.user@smartaid.local` | `SmartAidDemo2026!` |
| Volunteer workspace | `demo.volunteer@smartaid.local` | `SmartAidDemo2026!` |
| EMS control center | `demo.ems@smartaid.local` | `SmartAidDemo2026!` |

These accounts are strictly local fictional seed data. See [demo-runbook.md](demo-runbook.md) for a safe presentation sequence.

## 7. Verify everything before presenting

Run these commands from the project root:

```powershell
.\scripts\verify-all.ps1
.\scripts\test-end-to-end.ps1
.\scripts\build-android-debug.ps1
```

The first checks backend tests, Flutter formatting/analysis/tests, and the read-only demo scenario. The second runs a fictional stateful workflow through registration, SOS, volunteer dispatch, authenticated WebSocket updates, EMS, Smart ER, and resolution. The final command creates the Android debug APK at:

`mobile\build\app\outputs\flutter-apk\app-debug.apk`

If an E2E run is interrupted, run:

```powershell
.\scripts\cleanup-e2e.ps1
```

This only cancels incomplete, explicitly tagged fictional E2E records.
