package com.smartaid.platform.healthcare;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class MedicalProviderController {
    private final HealthcareService healthcare;

    public MedicalProviderController(HealthcareService healthcare) {
        this.healthcare = healthcare;
    }

    @GetMapping("/medical-providers")
    public List<MedicalProvider> listProviders(@RequestParam(required = false) String type) {
        return healthcare.listMedicalProviders(type);
    }

    @GetMapping("/medical-providers/{providerId}")
    public MedicalProvider getProvider(@PathVariable UUID providerId) {
        return healthcare.getMedicalProvider(providerId);
    }

    @PostMapping("/medical-providers")
    @PreAuthorize("hasAnyRole('DOCTOR', 'ADMIN')")
    public ResponseEntity<MedicalProvider> createProvider(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateMedicalProviderRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.createMedicalProvider(AuthContextHelper.userId(auth), request));
    }

    @PostMapping("/provider-appointments")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ProviderAppointment> bookAppointment(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateProviderAppointmentRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.bookProviderAppointment(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/provider-appointments")
    @PreAuthorize("hasAnyRole('DOCTOR', 'ADMIN')")
    public List<ProviderAppointment> allAppointments() {
        return healthcare.allProviderAppointments();
    }

    @GetMapping("/provider-appointments/mine")
    @PreAuthorize("isAuthenticated()")
    public List<ProviderAppointment> myAppointments(Authentication auth) {
        return healthcare.myProviderAppointments(AuthContextHelper.userId(auth));
    }

    @GetMapping("/provider-appointments/{appId}")
    @PreAuthorize("isAuthenticated()")
    public ProviderAppointment getAppointment(Authentication auth, @PathVariable UUID appId) {
        boolean privileged = AuthContextHelper.hasAnyRole(auth, "DOCTOR", "ADMIN");
        return healthcare.getProviderAppointment(appId, AuthContextHelper.userId(auth), privileged);
    }

    @PatchMapping("/provider-appointments/{appId}/status")
    @PreAuthorize("hasAnyRole('DOCTOR', 'ADMIN')")
    public ProviderAppointment updateStatus(
            Authentication auth,
            @PathVariable UUID appId,
            @Valid @RequestBody HealthcareDtos.UpdateStatusRequest request
    ) {
        return healthcare.updateProviderAppointmentStatus(AuthContextHelper.userId(auth), appId, request.status(), true);
    }

    @PostMapping("/provider-appointments/{appId}/cancel")
    @PreAuthorize("isAuthenticated()")
    public ProviderAppointment cancelAppointment(Authentication auth, @PathVariable UUID appId) {
        boolean privileged = AuthContextHelper.hasAnyRole(auth, "DOCTOR", "ADMIN");
        return healthcare.updateProviderAppointmentStatus(AuthContextHelper.userId(auth), appId, "CANCELLED", privileged);
    }
}
