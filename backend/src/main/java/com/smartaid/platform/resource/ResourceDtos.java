package com.smartaid.platform.resource;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

public class ResourceDtos {
    public record AedResponse(
        UUID id,
        String label,
        String resourceType,
        double latitude,
        double longitude,
        String availabilityStatus,
        boolean verified,
        Instant updatedAt,
        Double distanceMeters
    ) {}

    public record CreateAedRequest(
        @NotBlank String label,
        String resourceType,
        @NotNull Double latitude,
        @NotNull Double longitude,
        String availabilityStatus
    ) {}

    public record AmbulanceResponse(
        UUID id,
        String callSign,
        String status,
        Double latitude,
        Double longitude,
        Instant updatedAt
    ) {}

    public record CreateAmbulanceRequest(
        @NotBlank String callSign,
        String status,
        Double latitude,
        Double longitude
    ) {}

    public record UpdateAmbulanceStatusRequest(
        @NotBlank String status,
        Double latitude,
        Double longitude
    ) {}
}
