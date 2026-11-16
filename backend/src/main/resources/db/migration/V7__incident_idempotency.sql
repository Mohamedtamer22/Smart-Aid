-- A retry of the same client SOS command must resolve to the original incident,
-- not create a second dispatchable emergency. The paired application-level
-- advisory lock serializes same-user/same-key requests within PostgreSQL.
CREATE TABLE incident_idempotency_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  request_key VARCHAR(128) NOT NULL,
  request_fingerprint VARCHAR(64) NOT NULL,
  incident_id UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_incident_idempotency_key UNIQUE (reporter_id, request_key)
);

CREATE INDEX idx_incident_idempotency_incident
  ON incident_idempotency_keys (incident_id);
