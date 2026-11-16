package com.smartaid.platform.healthcare;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class MedicalHandoverController {
    private final HealthcareService healthcare;

    public MedicalHandoverController(HealthcareService healthcare) {
        this.healthcare = healthcare;
    }

    @PostMapping("/handovers")
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN')")
    public ResponseEntity<MedicalHandover> createHandover(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateHandoverRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.createHandover(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/handovers/pending")
    @PreAuthorize("hasAnyRole('HOSPITAL', 'EMS', 'DOCTOR', 'ADMIN')")
    public List<MedicalHandover> pendingHandovers() {
        return healthcare.pendingHandovers();
    }

    @GetMapping("/handovers/{handoverId}")
    @PreAuthorize("hasAnyRole('HOSPITAL', 'EMS', 'DOCTOR', 'ADMIN')")
    public MedicalHandover getHandover(@PathVariable UUID handoverId) {
        return healthcare.getHandover(handoverId);
    }

    @GetMapping("/handovers/incident/{incidentId}")
    @PreAuthorize("hasAnyRole('HOSPITAL', 'EMS', 'DOCTOR', 'ADMIN')")
    public MedicalHandover getByIncident(@PathVariable UUID incidentId) {
        return healthcare.getHandoverByIncident(incidentId);
    }

    @GetMapping("/incidents/{incidentId}/handover")
    @PreAuthorize("hasAnyRole('HOSPITAL', 'EMS', 'DOCTOR', 'ADMIN')")
    public MedicalHandover getByIncidentAlias(@PathVariable UUID incidentId) {
        return healthcare.getHandoverByIncident(incidentId);
    }

    @PostMapping("/handovers/{handoverId}/acknowledge")
    @PreAuthorize("hasAnyRole('HOSPITAL', 'DOCTOR', 'ADMIN')")
    public MedicalHandover acknowledge(
            Authentication auth,
            @PathVariable UUID handoverId,
            @Valid @RequestBody HealthcareDtos.AcknowledgeHandoverRequest request
    ) {
        return healthcare.acknowledgeHandover(AuthContextHelper.userId(auth), handoverId, request.receivingStaffName());
    }
}
