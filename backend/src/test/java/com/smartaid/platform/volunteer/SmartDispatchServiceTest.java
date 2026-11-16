package com.smartaid.platform.volunteer;

import static org.junit.jupiter.api.Assertions.assertEquals;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class SmartDispatchServiceTest {
    @Test void ranks_only_available_verified_and_certified_skill_matches() {
        SmartDispatchService service = new SmartDispatchService();
        SmartDispatchService.ResponderCandidate near = new SmartDispatchService.ResponderCandidate(UUID.randomUUID(), true, true, true, 30.01, 31.01, Set.of("CPR", "AED"));
        SmartDispatchService.ResponderCandidate unavailable = new SmartDispatchService.ResponderCandidate(UUID.randomUUID(), true, false, true, 30.001, 31.001, Set.of("CPR", "AED"));
        SmartDispatchService.ResponderCandidate missingSkill = new SmartDispatchService.ResponderCandidate(UUID.randomUUID(), true, true, true, 30.02, 31.02, Set.of("CPR"));
        List<SmartDispatchService.DispatchRecommendation> results = service.rank(30, 31, Set.of("CPR", "AED"), List.of(unavailable, missingSkill, near));
        assertEquals(1, results.size());
        assertEquals(near.userId(), results.get(0).responderId());
    }
}
