CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE roles (
  id SMALLSERIAL PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(254) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(120) NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_users_email ON users (email);

CREATE TABLE user_roles (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id SMALLINT NOT NULL REFERENCES roles(id),
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(64) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);

CREATE TABLE medical_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  blood_type VARCHAR(8),
  allergies TEXT,
  medications TEXT,
  emergency_notes TEXT,
  sharing_consent BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  full_name VARCHAR(120) NOT NULL,
  relationship VARCHAR(80),
  phone VARCHAR(32) NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE emergency_types (
  id SMALLSERIAL PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,
  label VARCHAR(100) NOT NULL
);

CREATE TABLE incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id),
  emergency_type_id SMALLINT NOT NULL REFERENCES emergency_types(id),
  source VARCHAR(20) NOT NULL CHECK (source IN ('MANUAL','SMARTWATCH','SENSOR','CRASH','OTHER')),
  status VARCHAR(32) NOT NULL CHECK (status IN ('NEW','SEARCHING','RESPONDER_ASSIGNED','EMS_ASSIGNED','AMBULANCE_ASSIGNED','IN_TRANSIT','HOSPITAL_SELECTED','AT_HOSPITAL','RESOLVED','CANCELLED')),
  priority VARCHAR(16) NOT NULL DEFAULT 'STANDARD' CHECK (priority IN ('LOW','STANDARD','HIGH','CRITICAL')),
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  location GEOGRAPHY(POINT, 4326),
  notes VARCHAR(1000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_incidents_reporter ON incidents(reporter_id, created_at DESC);
CREATE INDEX idx_incidents_status ON incidents(status, created_at DESC);
CREATE INDEX idx_incidents_location ON incidents USING GIST(location);

CREATE TABLE incident_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  from_status VARCHAR(32),
  to_status VARCHAR(32) NOT NULL,
  actor_id UUID REFERENCES users(id),
  reason VARCHAR(500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_status_history_incident ON incident_status_history(incident_id, created_at);

CREATE TABLE triage_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL UNIQUE REFERENCES incidents(id) ON DELETE CASCADE,
  conscious BOOLEAN,
  breathing BOOLEAN,
  severe_bleeding BOOLEAN,
  chest_pain BOOLEAN,
  fall_occurred BOOLEAN,
  traffic_accident BOOLEAN,
  summary VARCHAR(1000) NOT NULL,
  rule_version VARCHAR(32) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE volunteer_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  available BOOLEAN NOT NULL DEFAULT FALSE,
  latitude DOUBLE PRECISION CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION CHECK (longitude BETWEEN -180 AND 180),
  location GEOGRAPHY(POINT, 4326),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_volunteers_available ON volunteer_profiles(available, verified);
CREATE INDEX idx_volunteers_location ON volunteer_profiles USING GIST(location);

CREATE TABLE skills (
  id SMALLSERIAL PRIMARY KEY,
  code VARCHAR(64) NOT NULL UNIQUE,
  label VARCHAR(120) NOT NULL
);
CREATE TABLE volunteer_skills (
  volunteer_id UUID NOT NULL REFERENCES volunteer_profiles(user_id) ON DELETE CASCADE,
  skill_id SMALLINT NOT NULL REFERENCES skills(id),
  PRIMARY KEY(volunteer_id, skill_id)
);
CREATE TABLE certifications (
  id SMALLSERIAL PRIMARY KEY,
  code VARCHAR(64) NOT NULL UNIQUE,
  label VARCHAR(120) NOT NULL
);
CREATE TABLE volunteer_certifications (
  volunteer_id UUID NOT NULL REFERENCES volunteer_profiles(user_id) ON DELETE CASCADE,
  certification_id SMALLINT NOT NULL REFERENCES certifications(id),
  verified_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY(volunteer_id, certification_id)
);

CREATE TABLE hospitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(160) NOT NULL UNIQUE,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  location GEOGRAPHY(POINT, 4326),
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  estimated_congestion SMALLINT CHECK (estimated_congestion BETWEEN 0 AND 100),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_hospitals_location ON hospitals USING GIST(location);
CREATE TABLE hospital_specialties (
  hospital_id UUID NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
  specialty VARCHAR(80) NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY(hospital_id, specialty)
);
CREATE TABLE hospital_resources (
  hospital_id UUID NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
  resource_code VARCHAR(80) NOT NULL,
  available BOOLEAN NOT NULL DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  PRIMARY KEY(hospital_id, resource_code)
);

CREATE TABLE ambulances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_sign VARCHAR(50) NOT NULL UNIQUE,
  status VARCHAR(20) NOT NULL CHECK(status IN ('AVAILABLE','ASSIGNED','EN_ROUTE','ARRIVED','TRANSPORTING','AT_HOSPITAL','COMPLETED')),
  latitude DOUBLE PRECISION CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION CHECK (longitude BETWEEN -180 AND 180),
  location GEOGRAPHY(POINT, 4326),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ambulances_location ON ambulances USING GIST(location);
CREATE TABLE ambulance_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ambulance_id UUID NOT NULL REFERENCES ambulances(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  location GEOGRAPHY(POINT, 4326),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ambulance_tracking_vehicle ON ambulance_tracking(ambulance_id, recorded_at DESC);

CREATE TABLE emergency_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  volunteer_id UUID REFERENCES volunteer_profiles(user_id),
  ambulance_id UUID REFERENCES ambulances(id),
  response_status VARCHAR(32) NOT NULL,
  eta_minutes SMALLINT CHECK (eta_minutes >= 0),
  accepted_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_responses_incident ON emergency_responses(incident_id);

CREATE TABLE aed_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_type VARCHAR(32) NOT NULL CHECK(resource_type IN ('AED','FIRST_AID','OTHER_APPROVED_RESOURCE')),
  label VARCHAR(160) NOT NULL,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  location GEOGRAPHY(POINT, 4326),
  availability_status VARCHAR(32) NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_aed_location ON aed_devices USING GIST(location);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(40) NOT NULL CHECK(type IN ('EMERGENCY_ALERT','RESPONDER_ASSIGNED','INCIDENT_ACCEPTED','AMBULANCE_ASSIGNED','HOSPITAL_RECOMMENDED','STATUS_CHANGED','SYSTEM')),
  title VARCHAR(160) NOT NULL,
  body VARCHAR(1000) NOT NULL,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);

CREATE TABLE training_courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(160) NOT NULL,
  description TEXT,
  is_mock_content BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE training_lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES training_courses(id) ON DELETE CASCADE,
  title VARCHAR(160) NOT NULL,
  content TEXT NOT NULL,
  sort_order SMALLINT NOT NULL
);
CREATE TABLE training_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES training_courses(id) ON DELETE CASCADE,
  score NUMERIC(5,2),
  completed_at TIMESTAMPTZ,
  UNIQUE(user_id, course_id)
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES users(id),
  action VARCHAR(80) NOT NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id UUID,
  trace_id VARCHAR(64),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id, created_at DESC);

CREATE TABLE system_settings (
  setting_key VARCHAR(100) PRIMARY KEY,
  setting_value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION smartaid_set_geography() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.latitude IS NULL OR NEW.longitude IS NULL THEN NEW.location := NULL;
  ELSE NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_incident_geography BEFORE INSERT OR UPDATE OF latitude, longitude ON incidents FOR EACH ROW EXECUTE FUNCTION smartaid_set_geography();
CREATE TRIGGER trg_volunteer_geography BEFORE INSERT OR UPDATE OF latitude, longitude ON volunteer_profiles FOR EACH ROW EXECUTE FUNCTION smartaid_set_geography();
CREATE TRIGGER trg_hospital_geography BEFORE INSERT OR UPDATE OF latitude, longitude ON hospitals FOR EACH ROW EXECUTE FUNCTION smartaid_set_geography();
CREATE TRIGGER trg_ambulance_geography BEFORE INSERT OR UPDATE OF latitude, longitude ON ambulances FOR EACH ROW EXECUTE FUNCTION smartaid_set_geography();
CREATE TRIGGER trg_tracking_geography BEFORE INSERT OR UPDATE OF latitude, longitude ON ambulance_tracking FOR EACH ROW EXECUTE FUNCTION smartaid_set_geography();
CREATE TRIGGER trg_aed_geography BEFORE INSERT OR UPDATE OF latitude, longitude ON aed_devices FOR EACH ROW EXECUTE FUNCTION smartaid_set_geography();
