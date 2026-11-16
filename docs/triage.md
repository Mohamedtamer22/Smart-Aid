# Structured triage

The implemented form accepts structured reports for consciousness, breathing, severe bleeding, chest pain, fall, and traffic accident. `TriageService` records a plain-language rule summary and assigns a coordination priority: reported breathing concern, unconsciousness, or severe bleeding is `CRITICAL`; other reported concerns are `HIGH`; no flags are `STANDARD`.

This is not diagnosis, prescription, or an override of EMS. AI summarization is intentionally not implemented: it would require a governed, configured provider and review safeguards. The deterministic fallback is the only current behavior.
