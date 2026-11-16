# Smart Aid local presentation runbook

This runbook is for a controlled local demonstration only. All seeded names, accounts, incidents, hospitals, availability values, and recommendations are fictional. Smart Aid is a coordination and decision-support prototype; it must not be presented as a substitute for official emergency services or clinical judgment.

## Start

1. Confirm PostgreSQL 18 and PostGIS are running natively and that the local `.env` contains the database credentials.
2. Run `.\scripts\start-demo.ps1` from the repository root.
3. Wait for `http://localhost:8080/actuator/health` to return `UP`.
4. Run `.\scripts\verify-demo.ps1`; it performs non-mutating role, dashboard, Smart ER comparison, and authorization checks.
5. Launch the Flutter app with the appropriate local API address. Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`. Windows/web: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`.

## Fictional demo identities

The seeder runs only with `SMARTAID_DEMO_SEED=true` and may be run repeatedly without duplicating its sample records.

| Role | Email | Password |
| --- | --- | --- |
| Citizen | `demo.user@smartaid.local` | `SmartAidDemo2026!` |
| Verified volunteer | `demo.volunteer@smartaid.local` | `SmartAidDemo2026!` |
| EMS coordinator | `demo.ems@smartaid.local` | `SmartAidDemo2026!` |

These credentials belong only to the local seeded database. They are not production credentials and should not be reused elsewhere.

## Suggested flow

1. Sign in as the citizen and open **My incidents** to show server-confirmed status history.
2. Sign in as the verified volunteer and show readiness, skills/certification status, and nearby simulated alerts. Do not accept an alert before showing the initial state.
3. Sign in as EMS and show the operational dashboard and a fictional active case.
4. Open **Smart ER** for the simulated cardiac case. Emphasize that it compares capability, specialty fit, travel estimate, and expected congestion, then explains the ranking.
5. If desired, accept the simulated case as the volunteer to demonstrate the role-protected, auditable assignment change. Restarting with a fresh local database restores the pristine scenario.

## Safe wording during the presentation

- Say “simulated local incident,” “decision support,” and “based on available demonstration data.”
- Do not claim any hospital capacity, location, ETA, or emergency-resource availability is live or medically guaranteed.
- Do not press SOS to simulate a real emergency during a live presentation.
