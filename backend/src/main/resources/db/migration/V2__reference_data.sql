INSERT INTO roles (code) VALUES ('USER'), ('VOLUNTEER'), ('EMS'), ('ADMIN');
INSERT INTO emergency_types (code, label) VALUES
  ('MEDICAL', 'Medical emergency'), ('CARDIAC', 'Cardiac emergency'), ('TRAUMA', 'Trauma'), ('ACCIDENT', 'Traffic accident'), ('OTHER', 'Other');
INSERT INTO system_settings (setting_key, setting_value) VALUES
  ('smart_dispatch.weights', '{"distance":0.45,"eta":0.25,"skills":0.20,"certification":0.10}'::jsonb),
  ('smart_er.weights', '{"travelTime":0.30,"capability":0.30,"specialty":0.25,"congestion":0.15}'::jsonb);
