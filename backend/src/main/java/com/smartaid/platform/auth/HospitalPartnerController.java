package com.smartaid.platform.auth;

import com.smartaid.platform.exception.ApiException;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/hospital-partner")
public class HospitalPartnerController {
    private final HospitalPartnerRequestRepository requests;

    public HospitalPartnerController(HospitalPartnerRequestRepository requests) {
        this.requests = requests;
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('HOSPITAL')")
    AuthDtos.HospitalPartnerStatusResponse current(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        HospitalPartnerRequest request = requests.findByUserId(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "HOSPITAL_REQUEST_NOT_FOUND",
                        "No hospital partner request was found for this account"));
        return new AuthDtos.HospitalPartnerStatusResponse(request.getOrganizationName(), request.getRegistrationNumber(),
                request.getStatus(), request.getCreatedAt());
    }
}
