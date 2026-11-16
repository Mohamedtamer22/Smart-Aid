package com.smartaid.platform.disaster;

import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/disaster")
public class DisasterController {
    private final DisasterService disaster;

    public DisasterController(DisasterService disaster) {
        this.disaster = disaster;
    }

    @GetMapping("/status")
    public DisasterDtos.DisasterStatus status() {
        return disaster.getStatus();
    }

    @GetMapping("/overview")
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN', 'VOLUNTEER')")
    public DisasterDtos.DisasterOverview overview() {
        return disaster.getOverview();
    }

    @PostMapping("/activate")
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN')")
    public DisasterDtos.DisasterStatus activate(
        @Valid @RequestBody DisasterDtos.ActivateDisasterRequest request,
        Authentication authentication
    ) {
        UUID actorId = (UUID) authentication.getPrincipal();
        return disaster.activate(actorId, request);
    }

    @PostMapping("/deactivate")
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN')")
    public DisasterDtos.DisasterStatus deactivate(Authentication authentication) {
        UUID actorId = (UUID) authentication.getPrincipal();
        return disaster.deactivate(actorId);
    }

    @PatchMapping("/incidents/{incidentId}/triage")
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN', 'VOLUNTEER')")
    public void updateTriage(
        @PathVariable UUID incidentId,
        @Valid @RequestBody DisasterDtos.UpdateTriageTagRequest request,
        Authentication authentication
    ) {
        UUID actorId = (UUID) authentication.getPrincipal();
        disaster.updateTriageTag(actorId, incidentId, request.triageTag(), request.notes());
    }
}
