-- Hospital congestion is modelled as a Java Integer for transparent scoring.
-- Preserve the existing 0..100 check while aligning the physical column type.
ALTER TABLE hospitals
  ALTER COLUMN estimated_congestion TYPE INTEGER;
