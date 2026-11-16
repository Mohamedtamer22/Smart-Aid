package com.smartaid.platform.disaster;

import jakarta.validation.constraints.NotBlank;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public class DisasterDtos {
    public record DisasterStatus(
        boolean active,
        String disasterType,
        String disasterLevel,
        String affectedArea,
        Instant activatedAt,
        int activeIncidentsCount,
        int respondersMobilizedCount
    ) {}

    public record ActivateDisasterRequest(
        @NotBlank String disasterType,
        @NotBlank String disasterLevel,
        @NotBlank String affectedArea,
        Double centerLat,
        Double centerLng,
        Double radiusKm,
        String notes
    ) {}

    public record MassCasualtyIncident(
        UUID id,
        String emergencyType,
        String status,
        String priority,
        String triageTag, // RED, YELLOW, GREEN, BLACK
        double latitude,
        double longitude,
        String notes,
        Instant createdAt,
        int assignedRespondersCount
    ) {}

    public record UpdateTriageTagRequest(
        @NotBlank String triageTag,
        String notes
    ) {}

    public record DisasterOverview(
        DisasterStatus status,
        List<MassCasualtyIncident> priorityQueue,
        int redCount,
        int yellowCount,
        int greenCount,
        int blackCount
    ) {}
}
