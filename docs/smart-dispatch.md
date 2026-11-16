# Smart Dispatch

`SmartDispatchService` is a pure, unit-tested ranking rule. It excludes candidates who are unavailable, unverified, lack a currently verified non-expired certification, lack a required skill, or have no location. It ranks remaining candidates with transparent development weights: distance 45%, estimated ETA 25%, skill match 20%, certification 10%.

ETA uses a labeled 30 km/h straight-line estimate and is not navigation or a promise. The API returns responder ID, score, estimated minutes, matching skills, and reasons. Hospital/resource/volunteer tables intentionally contain no fabricated real-world seed data; an empty response means no verified candidate data is currently available.

The implemented volunteer workflow uses the same eligibility filters to list nearby `SEARCHING` incidents within the configurable `smartaid.dispatch.maximum-radius-km` (15 km by default). On acceptance, the service pessimistically locks the incident, checks for another active mission and a prior response, stores an `ACCEPTED` emergency response, then moves the incident to `RESPONDER_ASSIGNED`. This is auditable and prevents two volunteers from accepting the same incident concurrently. The volunteer may then record `ARRIVED` and `COMPLETED`; completing a volunteer mission does not resolve the overall medical incident.

Escalation notifications and navigation remain future slices. Before field use, weights require governance, simulation data, fairness review, and EMS approval.
