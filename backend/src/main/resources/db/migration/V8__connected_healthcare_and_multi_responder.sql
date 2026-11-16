-- ====================================================================
-- Smart Aid V8: Connected Healthcare Network & Multi-Responder Coordination
-- ====================================================================

-- 1. Multi-Responder Coordination (F03)
ALTER TABLE emergency_responses DROP CONSTRAINT IF EXISTS uq_emergency_responses_incident;
ALTER TABLE emergency_responses ADD COLUMN IF NOT EXISTS task_type VARCHAR(64) NOT NULL DEFAULT 'PRIMARY_RESPONSE';
ALTER TABLE emergency_responses ADD COLUMN IF NOT EXISTS task_notes TEXT;

-- Prevent duplicate assignment of the SAME volunteer to the same incident, but allow multiple responders
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_emergency_responses_incident_volunteer'
  ) THEN
    ALTER TABLE emergency_responses ADD CONSTRAINT uq_emergency_responses_incident_volunteer UNIQUE (incident_id, volunteer_id);
  END IF;
END $$;

-- 2. Extended Roles
INSERT INTO roles (code) VALUES 
  ('PHARMACIST'),
  ('LAB_STAFF'),
  ('BLOOD_BANK_STAFF'),
  ('DOCTOR')
ON CONFLICT (code) DO NOTHING;

-- 3. Smart Pharmacy & Emergency Supplies (F09)
CREATE TABLE IF NOT EXISTS pharmacies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(160) NOT NULL,
  address VARCHAR(255) NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  phone VARCHAR(32),
  opening_hours VARCHAR(120) NOT NULL DEFAULT '24/7',
  verified BOOLEAN NOT NULL DEFAULT TRUE,
  emergency_supplies_available BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS medicines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(160) NOT NULL,
  active_ingredient VARCHAR(160),
  dosage_form VARCHAR(64),
  is_emergency_supply BOOLEAN NOT NULL DEFAULT FALSE,
  prescription_required BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pharmacy_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
  medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
  stock_quantity INT NOT NULL DEFAULT 0,
  unit_price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_pharmacy_medicine UNIQUE (pharmacy_id, medicine_id)
);

CREATE TABLE IF NOT EXISTS medicine_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
  medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1,
  order_status VARCHAR(32) NOT NULL DEFAULT 'PLACED',
  delivery_requested BOOLEAN NOT NULL DEFAULT FALSE,
  delivery_address VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Smart Blood Bank (F11)
CREATE TABLE IF NOT EXISTS blood_banks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(160) NOT NULL,
  address VARCHAR(255) NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  phone VARCHAR(32),
  verified BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS blood_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blood_bank_id UUID NOT NULL REFERENCES blood_banks(id) ON DELETE CASCADE,
  blood_group VARCHAR(8) NOT NULL,
  units_available INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_blood_bank_group UNIQUE (blood_bank_id, blood_group)
);

CREATE TABLE IF NOT EXISTS blood_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blood_bank_id UUID REFERENCES blood_banks(id) ON DELETE SET NULL,
  incident_id UUID REFERENCES incidents(id) ON DELETE SET NULL,
  blood_group VARCHAR(8) NOT NULL,
  units_requested INT NOT NULL DEFAULT 1,
  urgency VARCHAR(32) NOT NULL DEFAULT 'STANDARD',
  status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Smart Lab (F10)
CREATE TABLE IF NOT EXISTS laboratories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(160) NOT NULL,
  address VARCHAR(255) NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  phone VARCHAR(32),
  verified BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lab_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  laboratory_id UUID NOT NULL REFERENCES laboratories(id) ON DELETE CASCADE,
  service_name VARCHAR(160) NOT NULL,
  category VARCHAR(64),
  turnaround_hours INT DEFAULT 24,
  price NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS lab_appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  laboratory_id UUID NOT NULL REFERENCES laboratories(id) ON DELETE CASCADE,
  lab_service_id UUID NOT NULL REFERENCES lab_services(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'BOOKED',
  result_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Smart Medical Services (F12)
CREATE TABLE IF NOT EXISTS medical_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(160) NOT NULL,
  provider_type VARCHAR(64) NOT NULL,
  specialty VARCHAR(120),
  address VARCHAR(255) NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  phone VARCHAR(32),
  verified BOOLEAN NOT NULL DEFAULT TRUE,
  telemedicine_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS provider_appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES medical_providers(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMPTZ NOT NULL,
  appointment_type VARCHAR(32) NOT NULL DEFAULT 'IN_PERSON',
  status VARCHAR(32) NOT NULL DEFAULT 'SCHEDULED',
  chief_complaint TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. Smart Medical Delivery (F13)
CREATE TABLE IF NOT EXISTS medical_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES medicine_orders(id) ON DELETE CASCADE,
  tracking_code VARCHAR(64) NOT NULL UNIQUE,
  courier_name VARCHAR(120),
  courier_phone VARCHAR(32),
  delivery_status VARCHAR(32) NOT NULL DEFAULT 'ASSIGNED',
  eta_minutes INT,
  pickup_address VARCHAR(255),
  delivery_address VARCHAR(255),
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. Smart Medical Handover (F15)
CREATE TABLE IF NOT EXISTS medical_handovers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  ems_responder_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiving_hospital_id UUID NOT NULL REFERENCES hospitals(id) ON DELETE CASCADE,
  receiving_staff_name VARCHAR(120),
  triage_summary TEXT,
  vital_signs TEXT,
  interventions_administered TEXT,
  allergy_alerts TEXT,
  medication_notes TEXT,
  handover_status VARCHAR(32) NOT NULL DEFAULT 'TRANSFERRED',
  transferred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  acknowledged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexing for high-throughput spatial and lookup operations
CREATE INDEX IF NOT EXISTS idx_pharmacies_verified ON pharmacies(verified);
CREATE INDEX IF NOT EXISTS idx_medicines_emergency ON medicines(is_emergency_supply);
CREATE INDEX IF NOT EXISTS idx_blood_banks_verified ON blood_banks(verified);
CREATE INDEX IF NOT EXISTS idx_blood_requests_status ON blood_requests(status, urgency);
CREATE INDEX IF NOT EXISTS idx_laboratories_verified ON laboratories(verified);
CREATE INDEX IF NOT EXISTS idx_medical_providers_type ON medical_providers(provider_type, verified);
CREATE INDEX IF NOT EXISTS idx_medical_handovers_incident ON medical_handovers(incident_id);
