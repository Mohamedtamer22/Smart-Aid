# Developer guide

Use feature branches such as `codex/auth`, `codex/emergency`, or `codex/smart-er` from `develop` once the repository receives its first commit. Keep `.env` local. Run tests before merging and update API/docs in the same change.

Run migrations only through the backend on a native PostgreSQL/PostGIS instance. Do not use Docker, Compose, Kubernetes, VM, or containerized dependencies. Do not directly edit a schema that Flyway owns; add a new migration.

For Android emulator access, configure `API_BASE_URL` with `--dart-define`; never hardcode `10.0.2.2` in source. The mobile app reports an SOS as created only after the backend returns `201 Created`.

For an Android presentation artifact, run `..\scripts\build-android-debug.ps1` from the project root. It uses Flutter's required native Gradle build, sets a Windows-safe temporary directory for that process, and outputs `mobile\build\app\outputs\flutter-apk\app-debug.apk`. The debug Android manifest permits local HTTP for the emulator-only development workflow; production deployment must use HTTPS.
