package com.smartaid.platform.incident;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

class IncidentStatusTest {
    @Test void lifecycle_accepts_expected_next_statuses() {
        assertTrue(IncidentStatus.NEW.allowedNext().contains(IncidentStatus.SEARCHING));
        assertTrue(IncidentStatus.AT_HOSPITAL.allowedNext().contains(IncidentStatus.RESOLVED));
        assertFalse(IncidentStatus.RESOLVED.allowedNext().contains(IncidentStatus.SEARCHING));
        assertFalse(IncidentStatus.NEW.allowedNext().contains(IncidentStatus.RESOLVED));
        assertTrue(IncidentStatus.SEARCHING.allowedNext().contains(IncidentStatus.EMS_ASSIGNED));
        assertTrue(IncidentStatus.RESPONDER_ASSIGNED.allowedNext().contains(IncidentStatus.EMS_ASSIGNED));
        assertFalse(IncidentStatus.CANCELLED.allowedNext().contains(IncidentStatus.EMS_ASSIGNED));
    }

    @Test void reporter_cancellation_ends_when_operational_coordination_starts() {
        assertTrue(IncidentStatus.NEW.canBeCancelledByReporter());
        assertTrue(IncidentStatus.SEARCHING.canBeCancelledByReporter());
        assertFalse(IncidentStatus.RESPONDER_ASSIGNED.canBeCancelledByReporter());
        assertFalse(IncidentStatus.EMS_ASSIGNED.canBeCancelledByReporter());
    }
}
