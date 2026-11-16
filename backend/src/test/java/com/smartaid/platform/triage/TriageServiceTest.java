package com.smartaid.platform.triage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

class TriageServiceTest {
    private final TriageService service = new TriageService();
    @Test void breathing_concern_is_flagged_as_critical_without_diagnosis() {
        TriageService.TriageResult result = service.summarize(new TriageInput(true, false, false, false, false, false));
        assertEquals("CRITICAL", result.priority());
        assertTrue(result.summary().contains("not a diagnosis"));
    }
}
