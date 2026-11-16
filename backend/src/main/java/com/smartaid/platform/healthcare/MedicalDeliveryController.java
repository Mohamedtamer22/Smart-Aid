package com.smartaid.platform.healthcare;

import jakarta.validation.Valid;
import java.util.List;
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
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/medical-deliveries")
public class MedicalDeliveryController {
    private final HealthcareService healthcare;

    public MedicalDeliveryController(HealthcareService healthcare) {
        this.healthcare = healthcare;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('PHARMACIST', 'ADMIN')")
    public List<MedicalDelivery> listDeliveries() {
        return healthcare.listDeliveries();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('PHARMACIST', 'ADMIN')")
    public ResponseEntity<MedicalDelivery> createDelivery(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateDeliveryRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.createDelivery(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/track/{trackingCode}")
    @PreAuthorize("isAuthenticated()")
    public MedicalDelivery track(@PathVariable String trackingCode) {
        return healthcare.trackDelivery(trackingCode);
    }

    @PatchMapping("/{trackingCode}/status")
    @PreAuthorize("hasAnyRole('PHARMACIST', 'ADMIN')")
    public MedicalDelivery updateStatus(
            Authentication auth,
            @PathVariable String trackingCode,
            @Valid @RequestBody HealthcareDtos.UpdateStatusRequest request
    ) {
        return healthcare.updateDeliveryStatus(AuthContextHelper.userId(auth), trackingCode, request.status(), null);
    }

    @PostMapping("/{trackingCode}/telemetry")
    @PreAuthorize("hasAnyRole('PHARMACIST', 'ADMIN')")
    public MedicalDelivery updateTelemetry(
            Authentication auth,
            @PathVariable String trackingCode,
            @Valid @RequestBody HealthcareDtos.DeliveryTelemetryRequest request
    ) {
        return healthcare.updateDeliveryStatus(AuthContextHelper.userId(auth), trackingCode, request.deliveryStatus(), request.etaMinutes());
    }
}
