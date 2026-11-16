package com.smartaid.platform.smarter;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.exception.ApiException;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/hospitals")
public class HospitalController {
    private final HospitalRepository hospitals;
    private final SmartErController smartErController;
    private final AuditService audit;

    public HospitalController(HospitalRepository hospitals, SmartErController smartErController, AuditService audit) {
        this.hospitals = hospitals;
        this.smartErController = smartErController;
        this.audit = audit;
    }

    @GetMapping
    List<HospitalDtos.HospitalResponse> verifiedHospitals() {
        return hospitals.findByVerifiedTrue().stream()
                .map(hospital -> new HospitalDtos.HospitalResponse(hospital.getId().toString(), hospital.getName(),
                        hospital.getLatitude(), hospital.getLongitude(), hospital.getUpdatedAt()))
                .sorted(Comparator.comparing(HospitalDtos.HospitalResponse::name, String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    /** Compatibility alias for GET /api/hospitals/recommendation/{incidentId} */
    @GetMapping("/recommendation/{incidentId}")
    List<SmartErService.HospitalRecommendation> recommendation(@PathVariable UUID incidentId) {
        return smartErController.recommendations(incidentId);
    }

    /** Authorized hospital staff, EMS, or Admin can update operational congestion and refresh data freshness timestamp. */
    @PatchMapping("/{hospitalId}/capacity")
    @PreAuthorize("hasAnyRole('HOSPITAL', 'EMS', 'ADMIN')")
    HospitalDtos.HospitalCapacityResponse updateCapacity(
            Authentication authentication,
            @PathVariable UUID hospitalId,
            @Valid @RequestBody HospitalDtos.UpdateCapacityRequest request
    ) {
        Hospital hospital = hospitals.findById(hospitalId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "HOSPITAL_NOT_FOUND", "Hospital was not found"));
        hospital.setEstimatedCongestion(request.estimatedCongestion());
        hospital.setUpdatedAt(Instant.now());
        Hospital saved = hospitals.save(hospital);
        if (audit != null && authentication != null && authentication.getPrincipal() instanceof UUID actorId) {
            audit.record(actorId, "HOSPITAL_CAPACITY_UPDATED", "HOSPITAL", saved.getId());
        }
        return new HospitalDtos.HospitalCapacityResponse(
                saved.getId().toString(),
                saved.getName(),
                saved.getEstimatedCongestion(),
                saved.getUpdatedAt(),
                request.sourceNote() != null ? request.sourceNote() : "Hospital Staff Manual Update"
        );
    }
}
