# Smart Aid presentation checklist

## Before the audience arrives

- [ ] Native PostgreSQL/PostGIS service is running; no Docker or container runtime is used.
- [ ] `.env` is configured locally and is not shared or committed.
- [ ] `.\scripts\start-demo.ps1` reports a healthy API.
- [ ] `.\scripts\verify-all.ps1` has passed for the current build.
- [ ] Flutter is connected to the correct API address for the chosen target.
- [ ] Sign in once with each fictional role and leave each screen in its intended starting state.
- [ ] Use a stable network-free local setup and disable unrelated notifications/pop-ups.
- [ ] Do not distribute the Android debug-signed build; production signing material remains outside the repository.

## Narrative order

1. **Citizen experience:** a concise, accessible SOS journey and clear server confirmation.
2. **Volunteer coordination:** verification, proximity/skills eligibility, and controlled assignment.
3. **EMS operations:** a role-protected operational view with traceable incident status.
4. **Smart ER:** an explainable recommendation—not a diagnosis—using transparent factors.
5. **Engineering trust:** native local stack, JWT/RBAC, audited transitions, PostGIS, bilingual/RTL UI, and automated checks.

## Non-negotiable disclosures

- All demonstration records are fictional and local.
- Smart Aid supports coordination and decisions; it never replaces emergency services or clinicians.
- The Smart ER score is an explainable engineering ranking based on available input data, not a medical guarantee.
