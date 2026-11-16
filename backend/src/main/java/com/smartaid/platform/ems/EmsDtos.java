package com.smartaid.platform.ems;

import com.smartaid.platform.incident.IncidentDtos;
import java.time.Instant;
import java.util.List;

public final class EmsDtos {
    private EmsDtos() { }

    public record IncidentSummary(String id, String emergencyType, String status, String priority,
                                  IncidentDtos.Location location, Instant createdAt) { }

    public record TimelineEvent(String fromStatus, String toStatus, String reason, Instant createdAt) { }

    public record IncidentDetail(IncidentSummary incident, String notes, List<TimelineEvent> timeline) { }

    public record DashboardResponse(int activeIncidents, int criticalIncidents, List<IncidentSummary> incidents) { }
}
