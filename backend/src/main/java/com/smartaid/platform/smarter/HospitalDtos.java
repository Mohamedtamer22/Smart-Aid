package com.smartaid.platform.smarter;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public final class HospitalDtos {
    private HospitalDtos() { }

    /** Publicly displayable resource directory data; operational capacity is not exposed here. */
    public record HospitalResponse(String id, String name, double latitude, double longitude, Instant updatedAt) { }

    public record UpdateCapacityRequest(
            @NotNull @Min(0) @Max(100) Integer estimatedCongestion,
            String sourceNote
    ) { }

    public record HospitalCapacityResponse(
            String id,
            String name,
            Integer estimatedCongestion,
            Instant updatedAt,
            String sourceNote
    ) { }
}
