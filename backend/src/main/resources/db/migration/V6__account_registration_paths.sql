-- Self-service registration never grants a verified operational organization.
-- A hospital applicant receives a pending partner request until an accountable
-- reviewer verifies the organization and creates/links a real hospital record.
INSERT INTO roles (code) VALUES ('HOSPITAL') ON CONFLICT (code) DO NOTHING;

CREATE TABLE hospital_partner_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  organization_name VARCHAR(160) NOT NULL,
  registration_number VARCHAR(100),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'DECLINED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_hospital_partner_requests_status ON hospital_partner_requests(status, created_at DESC);
