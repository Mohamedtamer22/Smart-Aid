package com.smartaid.platform.healthcare;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class LaboratoryController {
    private final HealthcareService healthcare;

    public LaboratoryController(HealthcareService healthcare) {
        this.healthcare = healthcare;
    }

    @GetMapping("/laboratories")
    public List<Laboratory> listLaboratories() {
        return healthcare.listLaboratories();
    }

    @PostMapping("/laboratories")
    @PreAuthorize("hasAnyRole('LAB_STAFF', 'ADMIN')")
    public ResponseEntity<Laboratory> createLaboratory(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateLaboratoryRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.createLaboratory(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/laboratories/{labId}/services")
    public List<LabServiceEntity> listServices(@PathVariable UUID labId) {
        return healthcare.listLabServices(labId);
    }

    @PostMapping("/laboratories/{labId}/services")
    @PreAuthorize("hasAnyRole('LAB_STAFF', 'ADMIN')")
    public ResponseEntity<LabServiceEntity> createService(
            Authentication auth,
            @PathVariable UUID labId,
            @Valid @RequestBody HealthcareDtos.CreateLabServiceRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.createLabService(AuthContextHelper.userId(auth), labId, request));
    }

    @PostMapping("/lab-appointments")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<LabAppointment> bookAppointment(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateLabAppointmentRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.bookLabAppointment(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/lab-appointments")
    @PreAuthorize("hasAnyRole('LAB_STAFF', 'DOCTOR', 'ADMIN')")
    public List<LabAppointment> allAppointments() {
        return healthcare.allLabAppointments();
    }

    @GetMapping("/lab-appointments/mine")
    @PreAuthorize("isAuthenticated()")
    public List<LabAppointment> myAppointments(Authentication auth) {
        return healthcare.myLabAppointments(AuthContextHelper.userId(auth));
    }

    @GetMapping("/lab-appointments/{appId}")
    @PreAuthorize("isAuthenticated()")
    public LabAppointment getAppointment(Authentication auth, @PathVariable UUID appId) {
        boolean privileged = AuthContextHelper.hasAnyRole(auth, "LAB_STAFF", "DOCTOR", "ADMIN");
        return healthcare.getLabAppointment(appId, AuthContextHelper.userId(auth), privileged);
    }

    @PatchMapping("/lab-appointments/{appId}/status")
    @PreAuthorize("hasAnyRole('LAB_STAFF', 'ADMIN')")
    public LabAppointment updateStatus(
            Authentication auth,
            @PathVariable UUID appId,
            @Valid @RequestBody HealthcareDtos.UpdateStatusRequest request
    ) {
        return healthcare.updateLabAppointmentStatus(AuthContextHelper.userId(auth), appId, request.status());
    }

    @PutMapping("/lab-appointments/{appId}/result")
    @PreAuthorize("hasAnyRole('LAB_STAFF', 'DOCTOR', 'ADMIN')")
    public LabAppointment submitResult(
            Authentication auth,
            @PathVariable UUID appId,
            @Valid @RequestBody HealthcareDtos.SubmitLabResultRequest request
    ) {
        return healthcare.submitLabResult(AuthContextHelper.userId(auth), appId, request.resultSummary());
    }

    @GetMapping("/lab-appointments/{appId}/report")
    @PreAuthorize("isAuthenticated()")
    public Map<String, Object> getReport(Authentication auth, @PathVariable UUID appId) {
        boolean privileged = AuthContextHelper.hasAnyRole(auth, "LAB_STAFF", "DOCTOR", "ADMIN");
        LabAppointment app = healthcare.getLabAppointment(appId, AuthContextHelper.userId(auth), privileged);
        return Map.of(
                "appointmentId", app.getId(),
                "status", app.getStatus(),
                "resultSummary", app.getResultSummary() != null ? app.getResultSummary() : "Pending laboratory verification",
                "updatedAt", app.getUpdatedAt()
        );
    }
}
