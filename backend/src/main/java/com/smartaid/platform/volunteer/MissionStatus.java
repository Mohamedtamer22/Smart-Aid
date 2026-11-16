package com.smartaid.platform.volunteer;

import java.util.EnumSet;
import java.util.Set;

public enum MissionStatus {
    ACCEPTED, ARRIVED, COMPLETED, CANCELLED;

    public Set<MissionStatus> allowedNext() {
        return switch (this) {
            case ACCEPTED -> EnumSet.of(ARRIVED, CANCELLED);
            case ARRIVED -> EnumSet.of(COMPLETED, CANCELLED);
            case COMPLETED, CANCELLED -> EnumSet.noneOf(MissionStatus.class);
        };
    }

    public boolean isActive() {
        return this == ACCEPTED || this == ARRIVED;
    }
}
