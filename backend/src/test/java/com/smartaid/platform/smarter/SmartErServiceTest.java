package com.smartaid.platform.smarter;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import com.smartaid.platform.config.SmartErProperties;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class SmartErServiceTest {
    @Test void excludes_missing_capability_and_explains_missing_congestion() {
        SmartErService service = new SmartErService(new SmartErProperties(.30, .30, .25, .15));
        SmartErService.HospitalCandidate eligible = new SmartErService.HospitalCandidate(UUID.randomUUID(), "Verified A", true, 8, true, true, null);
        SmartErService.HospitalCandidate noResource = new SmartErService.HospitalCandidate(UUID.randomUUID(), "No resource", true, 3, true, false, 10);
        List<SmartErService.HospitalRecommendation> results = service.rank(List.of(eligible, noResource));
        assertEquals(1, results.size());
        assertEquals("Verified A", results.get(0).hospitalName());
        assertTrue(results.get(0).reasons().stream().anyMatch(reason -> reason.contains("unavailable")));
    }
    @Test void different_weights_change_the_winner() {
        var fastButCongested = new SmartErService.HospitalCandidate(UUID.randomUUID(), "Fast", true, 5, true, true, 90);
        var slowerClear = new SmartErService.HospitalCandidate(UUID.randomUUID(), "Clear", true, 15, true, true, 0);
        var service = new SmartErService(new SmartErProperties(.05, .10, .10, .75));
        assertEquals("Clear", service.rank(List.of(fastButCongested, slowerClear)).get(0).hospitalName());
    }
}
