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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class BloodBankController {
    private final HealthcareService healthcare;

    public BloodBankController(HealthcareService healthcare) {
        this.healthcare = healthcare;
    }

    @GetMapping("/blood-banks")
    public List<BloodBank> listBloodBanks() {
        return healthcare.listBloodBanks();
    }

    @GetMapping("/blood-banks/{bankId}")
    public BloodBank getBloodBank(@PathVariable UUID bankId) {
        return healthcare.getBloodBank(bankId);
    }

    @PostMapping("/blood-banks")
    @PreAuthorize("hasAnyRole('BLOOD_BANK_STAFF', 'ADMIN')")
    public ResponseEntity<BloodBank> createBloodBank(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateBloodBankRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.createBloodBank(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/blood-banks/inventory")
    public List<BloodInventory> searchInventory(@RequestParam(required = false) String bloodGroup) {
        return healthcare.searchBloodInventory(bloodGroup);
    }

    @GetMapping("/blood-banks/{bankId}/inventory")
    public List<BloodInventory> getBankInventory(@PathVariable UUID bankId) {
        return healthcare.getBloodBankInventory(bankId);
    }

    @PutMapping("/blood-banks/{bankId}/inventory/{bloodGroup}")
    @PreAuthorize("hasAnyRole('BLOOD_BANK_STAFF', 'ADMIN')")
    public BloodInventory updateInventory(
            Authentication auth,
            @PathVariable UUID bankId,
            @PathVariable String bloodGroup,
            @Valid @RequestBody HealthcareDtos.UpdateBloodInventoryRequest request
    ) {
        return healthcare.updateBloodInventory(AuthContextHelper.userId(auth), bankId, bloodGroup, request.unitsAvailable());
    }

    @PostMapping("/blood-requests")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<BloodRequest> createBloodRequest(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateBloodRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.createBloodRequest(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/blood-requests")
    @PreAuthorize("isAuthenticated()")
    public List<BloodRequest> listBloodRequests(Authentication auth) {
        boolean privileged = AuthContextHelper.hasAnyRole(auth, "BLOOD_BANK_STAFF", "HOSPITAL", "EMS", "ADMIN");
        return healthcare.listBloodRequests(AuthContextHelper.userId(auth), privileged);
    }

    @GetMapping("/blood-requests/{reqId}")
    @PreAuthorize("isAuthenticated()")
    public BloodRequest getBloodRequest(Authentication auth, @PathVariable UUID reqId) {
        boolean privileged = AuthContextHelper.hasAnyRole(auth, "BLOOD_BANK_STAFF", "HOSPITAL", "EMS", "ADMIN");
        return healthcare.getBloodRequest(reqId, AuthContextHelper.userId(auth), privileged);
    }

    @PatchMapping("/blood-requests/{reqId}/status")
    @PreAuthorize("hasAnyRole('BLOOD_BANK_STAFF', 'HOSPITAL', 'ADMIN')")
    public BloodRequest updateBloodRequestStatus(
            Authentication auth,
            @PathVariable UUID reqId,
            @Valid @RequestBody HealthcareDtos.UpdateStatusRequest request
    ) {
        return healthcare.updateBloodRequestStatus(AuthContextHelper.userId(auth), reqId, request.status());
    }
}
