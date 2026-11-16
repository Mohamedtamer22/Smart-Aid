# UI flows

The implemented user flow is:

```text
Sign in/register → Home → optional structured check-in → SOS confirmation → location permission/location
→ POST /api/incidents → 201 confirmed → Active emergency map/status
```

If location, permission, network, or session handling fails, the client does not claim that an alert was created. The optional check-in is a rule-based coordination aid, not a diagnosis. The home has accessible SOS semantics, a large target, contextual safety language, dynamic Material text, English/Arabic locales, persisted language preference, and RTL support from locale directionality.

User profile routes now provide a secure medical-profile editor, emergency-contact CRUD, notification inbox, incident history, and detailed incident timeline. Each data screen has loading, empty, and retry states. The resources page deliberately remains empty until verified hospital/AED data and APIs exist; it must not invent real-world availability.

The implemented volunteer flow is:

```text
Verified VOLUNTEER sign-in → readiness dashboard → share location / set availability
→ eligible nearby incidents → accept confirmed incident → active mission
→ mark arrived → complete volunteer mission
```

The dashboard explicitly shows verification, certification, availability, and location readiness. It disables the nearby-incident action until the backend declares the profile eligible, uses device-location permission feedback, and never lets the client self-verify or self-certify. Acceptance is only shown as successful after the server returns a mission.

The implemented EMS flow is:

```text
EMS sign-in → operations dashboard → active/critical incident overview
→ start EMS coordination for SEARCHING or RESPONDER_ASSIGNED incident
→ EMS_ASSIGNED timeline event → Smart ER recommendation comparison
```

The current EMS dashboard is an initial operational view: it is server-role protected, excludes terminal incidents, and presents an action only when the backend permits the transition. Its Smart ER screen shows only backend-ranked verified candidates, score components, transparent reasons, and ETA caveats; it does not select a hospital itself. Ambulance control, hospital selection, live-map tracking, and full EMS incident detail UI remain future work.
