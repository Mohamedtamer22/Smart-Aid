package com.smartaid.platform.incident;

import com.smartaid.platform.triage.TriageInput;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;

public final class IncidentDtos {
    private IncidentDtos() { }
    public record Location(@NotNull @DecimalMin("-90.0") @DecimalMax("90.0") Double latitude,
                           @NotNull @DecimalMin("-180.0") @DecimalMax("180.0") Double longitude) { }
    public record CreateIncidentRequest(@NotBlank String emergencyType, @Valid @NotNull Location location,
                                        @Size(max = 1000) String notes, @Valid TriageInput triage) { }
    public record ChangeStatusRequest(@NotNull IncidentStatus status, @Size(max = 500) String reason) { }
    public record IncidentResponse(String id, String emergencyType, String source, String status, String priority,
                                   Location location, String notes, Instant createdAt) { }
    public record TimelineEvent(String status, String reason, Instant occurredAt) { }
    public record IncidentDetailResponse(IncidentResponse incident, List<TimelineEvent> timeline) { }
}
