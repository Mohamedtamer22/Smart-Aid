ALTER TABLE emergency_responses
  ADD COLUMN arrived_at TIMESTAMPTZ,
  ADD COLUMN updated_at TIMESTAMPTZ;

UPDATE emergency_responses SET updated_at = created_at WHERE updated_at IS NULL;

ALTER TABLE emergency_responses
  ALTER COLUMN updated_at SET NOT NULL,
  ADD CONSTRAINT chk_emergency_responses_status
    CHECK (response_status IN ('ACCEPTED', 'ARRIVED', 'COMPLETED', 'CANCELLED')),
  ADD CONSTRAINT uq_emergency_responses_incident UNIQUE (incident_id);

CREATE INDEX idx_emergency_responses_volunteer_active
  ON emergency_responses (volunteer_id, response_status, created_at DESC);
