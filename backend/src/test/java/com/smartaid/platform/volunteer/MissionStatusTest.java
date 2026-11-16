package com.smartaid.platform.volunteer;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

class MissionStatusTest {
    @Test
    void mission_lifecycle_requires_arrival_before_completion() {
        assertTrue(MissionStatus.ACCEPTED.allowedNext().contains(MissionStatus.ARRIVED));
        assertFalse(MissionStatus.ACCEPTED.allowedNext().contains(MissionStatus.COMPLETED));
        assertTrue(MissionStatus.ARRIVED.allowedNext().contains(MissionStatus.COMPLETED));
        assertFalse(MissionStatus.COMPLETED.allowedNext().contains(MissionStatus.ARRIVED));
    }
}
