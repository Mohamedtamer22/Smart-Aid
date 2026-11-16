# Smart Aid mobile

The Flutter client for Smart Aid’s controlled emergency-coordination prototype. It has role-aware user, volunteer and EMS surfaces, secure token storage, English/Arabic localization, manual SOS, profiles/contacts, notifications, deterministic decision-support views and authenticated API integration.

## Run locally

From this directory:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Use `http://localhost:8080` for browser/Windows/iOS simulator development and an intentionally configured LAN URL for a physical device. The backend must be started against the native PostgreSQL/PostGIS setup first; see [the repository setup guide](../docs/SETUP_AND_RUN.md).

This application is decision-support software. It does not contact emergency services, provide a medical diagnosis, guarantee a dispatch, hospital capacity, or route ETA.
