package com.smartaid.platform.volunteer;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;

public final class VolunteerDtos {
    private VolunteerDtos() { }

    public record Coordinates(
            @NotNull @DecimalMin("-90.0") @DecimalMax("90.0") Double latitude,
            @NotNull @DecimalMin("-180.0") @DecimalMax("180.0") Double longitude) { }

    public record AvailabilityRequest(@NotNull Boolean available) { }

    public record UpdateMissionRequest(@NotNull MissionStatus status) { }

    public record VolunteerProfileResponse(boolean verified, boolean available, Coordinates location,
                                           boolean certificationValid, List<String> skills, boolean dispatchEligible) { }

    public record IncidentPreview(String id, String emergencyType, String priority, Coordinates location,
                                  Instant createdAt) { }

    public record NearbyIncidentResponse(IncidentPreview incident, double distanceKm, int estimatedEtaMinutes,
                                         List<String> matchingSkills) { }

    public record MissionResponse(String id, String status, int estimatedEtaMinutes, IncidentPreview incident,
                                  Instant acceptedAt, Instant arrivedAt, Instant completedAt,
                                  String taskType, String taskNotes) {
        public MissionResponse(String id, String status, int estimatedEtaMinutes, IncidentPreview incident,
                               Instant acceptedAt, Instant arrivedAt, Instant completedAt) {
            this(id, status, estimatedEtaMinutes, incident, acceptedAt, arrivedAt, completedAt, "PRIMARY_RESPONSE", null);
        }
    }

    public record VolunteerDashboardResponse(VolunteerProfileResponse profile, MissionResponse activeMission,
                                             int nearbyEligibleIncidents) { }
}
