package com.smartaid.platform.incident;

import java.util.EnumSet;
import java.util.Set;

public enum IncidentStatus {
    NEW, SEARCHING, RESPONDER_ASSIGNED, EMS_ASSIGNED, AMBULANCE_ASSIGNED, IN_TRANSIT, HOSPITAL_SELECTED, AT_HOSPITAL, RESOLVED, CANCELLED;
    public Set<IncidentStatus> allowedNext() {
        return switch (this) {
            case NEW -> EnumSet.of(SEARCHING, CANCELLED);
            case SEARCHING -> EnumSet.of(RESPONDER_ASSIGNED, EMS_ASSIGNED, AMBULANCE_ASSIGNED, CANCELLED);
            case RESPONDER_ASSIGNED -> EnumSet.of(EMS_ASSIGNED, AMBULANCE_ASSIGNED, CANCELLED);
            case EMS_ASSIGNED -> EnumSet.of(AMBULANCE_ASSIGNED, HOSPITAL_SELECTED, CANCELLED);
            case AMBULANCE_ASSIGNED -> EnumSet.of(IN_TRANSIT, HOSPITAL_SELECTED, CANCELLED);
            case IN_TRANSIT -> EnumSet.of(HOSPITAL_SELECTED, AT_HOSPITAL, CANCELLED);
            case HOSPITAL_SELECTED -> EnumSet.of(AT_HOSPITAL, CANCELLED);
            case AT_HOSPITAL -> EnumSet.of(RESOLVED);
            case RESOLVED, CANCELLED -> EnumSet.noneOf(IncidentStatus.class);
        };
    }
    public boolean isTerminal() {
        return this == RESOLVED || this == CANCELLED;
    }

    /** A reporter may retract only before an operational response is assigned. */
    public boolean canBeCancelledByReporter() {
        return this == NEW || this == SEARCHING;
    }
}
