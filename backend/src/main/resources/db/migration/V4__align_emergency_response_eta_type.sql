-- The API models ETA in minutes as a Java Integer. Keep the persisted type aligned
-- with Hibernate validation and preserve every existing non-negative value.
ALTER TABLE emergency_responses
  ALTER COLUMN eta_minutes TYPE INTEGER;
