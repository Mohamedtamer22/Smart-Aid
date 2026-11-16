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
public class PharmacyController {
    private final HealthcareService healthcare;

    public PharmacyController(HealthcareService healthcare) {
        this.healthcare = healthcare;
    }

    @GetMapping("/pharmacies")
    public List<Pharmacy> listPharmacies(@RequestParam(defaultValue = "false") boolean emergencySuppliesOnly) {
        return healthcare.listPharmacies(emergencySuppliesOnly);
    }

    @GetMapping("/pharmacies/{pharmacyId}")
    public Pharmacy getPharmacy(@PathVariable UUID pharmacyId) {
        return healthcare.getPharmacy(pharmacyId);
    }

    @PostMapping("/pharmacies")
    @PreAuthorize("hasAnyRole('ADMIN', 'PHARMACIST')")
    public ResponseEntity<Pharmacy> createPharmacy(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreatePharmacyRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.createPharmacy(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/medicines")
    public List<Medicine> listMedicines(
            @RequestParam(required = false) String query,
            @RequestParam(defaultValue = "false") boolean emergencySuppliesOnly
    ) {
        return healthcare.searchMedicines(query, emergencySuppliesOnly);
    }

    @GetMapping("/medicines/search")
    public List<Medicine> searchMedicines(
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "false") boolean emergencySuppliesOnly
    ) {
        return healthcare.searchMedicines(q, emergencySuppliesOnly);
    }

    @GetMapping("/pharmacies/{pharmacyId}/inventory")
    public List<HealthcareDtos.PharmacyInventoryItemResponse> getInventory(@PathVariable UUID pharmacyId) {
        return healthcare.getPharmacyInventory(pharmacyId);
    }

    @PutMapping("/pharmacies/{pharmacyId}/inventory/{medicineId}")
    @PreAuthorize("hasAnyRole('PHARMACIST', 'ADMIN')")
    public PharmacyInventory updateInventory(
            Authentication auth,
            @PathVariable UUID pharmacyId,
            @PathVariable UUID medicineId,
            @Valid @RequestBody HealthcareDtos.UpdateInventoryRequest request
    ) {
        return healthcare.updatePharmacyInventory(AuthContextHelper.userId(auth), pharmacyId, medicineId, request);
    }

    @PostMapping("/pharmacies/orders")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<MedicineOrder> placeOrder(
            Authentication auth,
            @Valid @RequestBody HealthcareDtos.CreateMedicineOrderRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(healthcare.placeMedicineOrder(AuthContextHelper.userId(auth), request));
    }

    @GetMapping("/pharmacies/orders/mine")
    @PreAuthorize("isAuthenticated()")
    public List<MedicineOrder> myOrders(Authentication auth) {
        return healthcare.myMedicineOrders(AuthContextHelper.userId(auth));
    }

    @GetMapping("/pharmacies/orders/pending")
    @PreAuthorize("hasAnyRole('PHARMACIST', 'ADMIN')")
    public List<MedicineOrder> pendingOrders() {
        return healthcare.pendingMedicineOrders();
    }

    @GetMapping("/pharmacies/orders/{orderId}")
    @PreAuthorize("isAuthenticated()")
    public MedicineOrder getOrder(Authentication auth, @PathVariable UUID orderId) {
        boolean privileged = AuthContextHelper.hasAnyRole(auth, "PHARMACIST", "ADMIN");
        return healthcare.getMedicineOrder(orderId, AuthContextHelper.userId(auth), privileged);
    }

    @PatchMapping("/pharmacies/orders/{orderId}/status")
    @PreAuthorize("hasAnyRole('PHARMACIST', 'ADMIN')")
    public MedicineOrder updateOrderStatus(
            Authentication auth,
            @PathVariable UUID orderId,
            @Valid @RequestBody HealthcareDtos.UpdateStatusRequest request
    ) {
        return healthcare.updateMedicineOrderStatus(AuthContextHelper.userId(auth), orderId, request.status());
    }
}
