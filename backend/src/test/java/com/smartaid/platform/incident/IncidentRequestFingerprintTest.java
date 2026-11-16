package com.smartaid.platform.incident;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.smartaid.platform.triage.TriageInput;
import org.junit.jupiter.api.Test;

class IncidentRequestFingerprintTest {
    @Test
    void accepts_url_safe_keys_and_rejects_unsafe_values() {
        assertEquals("sos_retry-2026.10", IncidentRequestFingerprint.validatedKey("sos_retry-2026.10"));
        assertThrows(IllegalArgumentException.class, () -> IncidentRequestFingerprint.validatedKey("short"));
        assertThrows(IllegalArgumentException.class, () -> IncidentRequestFingerprint.validatedKey("unsafe key value"));
    }

    @Test
    void is_stable_for_the_same_sos_but_detects_a_changed_payload() {
        IncidentDtos.CreateIncidentRequest original = request(31.2357);
        assertEquals(IncidentRequestFingerprint.forRequest(original), IncidentRequestFingerprint.forRequest(request(31.2357)));
        assertNotEquals(IncidentRequestFingerprint.forRequest(original), IncidentRequestFingerprint.forRequest(request(31.2358)));
    }

    private IncidentDtos.CreateIncidentRequest request(double longitude) {
        return new IncidentDtos.CreateIncidentRequest("MEDICAL", new IncidentDtos.Location(30.0444, longitude), "Help needed",
                new TriageInput(true, true, false, false, false, false));
    }
}
