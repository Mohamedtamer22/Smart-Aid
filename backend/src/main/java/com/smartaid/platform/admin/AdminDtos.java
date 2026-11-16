package com.smartaid.platform.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public class AdminDtos {
    public record SystemOverview(
        long totalUsers,
        long totalVolunteers,
        long pendingVolunteerVerifications,
        long activeIncidents,
        long totalHospitals,
        long totalAmbulances,
        long totalAeds
    ) {}

    public record UserSummary(
        UUID id,
        String email,
        String displayName,
        boolean enabled,
        List<String> roles,
        Instant createdAt
    ) {}

    public record UpdateUserRolesRequest(
        @NotEmpty List<String> roles
    ) {}

    public record UpdateUserStatusRequest(
        boolean enabled
    ) {}

    public record VolunteerSummary(
        UUID userId,
        String email,
        String displayName,
        boolean verified,
        boolean available,
        Double latitude,
        Double longitude,
        Instant updatedAt
    ) {}

    public record CreateHospitalRequest(
        @NotBlank String name,
        @NotNull Double latitude,
        @NotNull Double longitude,
        Integer estimatedCongestion,
        List<String> specialties,
        List<String> resources
    ) {}

    public record AuditLogEntry(
        UUID id,
        UUID actorId,
        String action,
        String entityType,
        UUID entityId,
        String traceId,
        Instant createdAt
    ) {}
}
