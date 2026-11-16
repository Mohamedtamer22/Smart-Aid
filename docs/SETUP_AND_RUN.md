# Set Up and Run Smart Aid (V1 Edition)

Smart Aid is a complete, production-grade emergency response and healthcare coordination application.

---

## 1. System Requirements & Architecture

- **Operating System:** Windows, Linux, or macOS.
- **Backend:** Java 17 LTS (or 21 LTS) with Maven Wrapper (`./mvnw` or `.\mvnw.cmd`).
- **Frontend / Mobile:** Flutter 3.44.8+ and Dart 3.12.2+.
- **Database:** PostgreSQL 18 (or 15+) with PostGIS extensions installed and listening on `localhost:5432`.
- **API & Broker:** Spring Boot 3.5.0 on port 8080 with embedded STOMP WebSocket broker on `/ws`.

---

## 2. Quick Start Commands

### Step 1: Database Verification
Smart Aid expects PostgreSQL running locally with database `smartaid` and role `smartaid_user`:
```powershell
# Verify PostgreSQL service status
Get-Service -Name "postgresql-x64-*"
```
*(If bootstrapping from scratch on a clean machine, execute `database/bootstrap.sql` once via `psql -U postgres -f database/bootstrap.sql`)*

### Step 2: Start the Backend Service
From the repository root:
```powershell
cd d:\hamo\Projects\SmartAid\backend
.\mvnw.cmd spring-boot:run
```
- **Actuator Health Check:** [http://localhost:8080/actuator/health](http://localhost:8080/actuator/health)
- **Interactive Swagger / OpenAPI Docs:** [http://localhost:8080/swagger-ui/index.html](http://localhost:8080/swagger-ui/index.html)

### Step 3: Run the Automated Verification Scripts
Verify the live backend and all REST/WebSocket workflows:
```powershell
# Fast demo sanity check
powershell -ExecutionPolicy Bypass -File .\scripts\verify-demo.ps1

# Full 14-stage end-to-end live integration test
powershell -ExecutionPolicy Bypass -File .\scripts\test-end-to-end.ps1
```

### Step 4: Run the Flutter Mobile Application
```powershell
cd d:\hamo\Projects\SmartAid\mobile
flutter pub get
flutter test
flutter run -d chrome  # or -d windows, or -d emulator-5554
```

---

## 3. Automated Test Commands

### Backend Automated Test Suite (JUnit 5 + Spring Boot)
```powershell
cd d:\hamo\Projects\SmartAid\backend
.\mvnw.cmd test
```
*Executes all 20 test cases covering Spring Security, Dispatch, Smart ER, Triage, Disaster Management, Analytics, Idempotency, and Training.*

### Flutter Mobile Test Suite (Widget & Unit Tests)
```powershell
cd d:\hamo\Projects\SmartAid\mobile
flutter analyze
flutter test
```
*Executes all 12 widget and unit tests with 0 analysis issues.*

---

## 4. Demo Accounts & Quick Persona Switcher

When running with local seed data enabled (`SMARTAID_DEMO_SEED=true`), use these local demonstration accounts:

| Role | Email | Password | Primary Interface |
| :--- | :--- | :--- | :--- |
| **Citizen (Reporter)** | `demo.user@smartaid.local` | `SmartAidDemo2026!` | Pulsing SOS, Medical Profile, Contacts |
| **Field Volunteer** | `demo.volunteer@smartaid.local` | `SmartAidDemo2026!` | Nearby Incidents, Mission Acceptance, Training |
| **EMS Dispatcher** | `demo.ems@smartaid.local` | `SmartAidDemo2026!` | Operations Center, Fleet, Smart ER Dispatch |
| **System Administrator** | `demo.admin@smartaid.local` | `SmartAidDemo2026!` | KPI Analytics, Roster, Verifications, Audit Logs |

> [!TIP]
> **One-Tap Persona Switching:**  
> Tap the swap icon (`swap_horiz_rounded`) in the AppBar of any dashboard or go to **Settings → Demo & Roles → Switch Demo Persona** to immediately log in as any role without typing passwords.
