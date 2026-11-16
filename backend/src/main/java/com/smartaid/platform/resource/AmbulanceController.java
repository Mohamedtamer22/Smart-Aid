package com.smartaid.platform.resource;

import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.NonNull;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/ambulances")
public class AmbulanceController {
    private final AmbulanceRepository ambulances;

    public AmbulanceController(AmbulanceRepository ambulances) {
        this.ambulances = ambulances;
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public List<ResourceDtos.AmbulanceResponse> listAll() {
        return ambulances.findAll().stream().map(this::toResponse).toList();
    }

    @GetMapping("/available")
    @PreAuthorize("isAuthenticated()")
    public List<ResourceDtos.AmbulanceResponse> listAvailable() {
        return ambulances.findByStatus("AVAILABLE").stream().map(this::toResponse).toList();
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN')")
    public ResponseEntity<ResourceDtos.AmbulanceResponse> create(@Valid @RequestBody ResourceDtos.CreateAmbulanceRequest request) {
        Ambulance ambulance = new Ambulance(
            request.callSign(),
            request.status() != null ? request.status() : "AVAILABLE",
            request.latitude(),
            request.longitude()
        );
        Ambulance saved = ambulances.save(ambulance);
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN')")
    public ResourceDtos.AmbulanceResponse updateStatus(
        @PathVariable @NonNull UUID id,
        @Valid @RequestBody ResourceDtos.UpdateAmbulanceStatusRequest request
    ) {
        Ambulance ambulance = ambulances.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Ambulance not found"));
        ambulance.setStatus(request.status());
        if (request.latitude() != null) ambulance.setLatitude(request.latitude());
        if (request.longitude() != null) ambulance.setLongitude(request.longitude());
        ambulance.setUpdatedAt(Instant.now());
        return toResponse(ambulances.save(ambulance));
    }

    private ResourceDtos.AmbulanceResponse toResponse(Ambulance a) {
        return new ResourceDtos.AmbulanceResponse(
            a.getId(),
            a.getCallSign(),
            a.getStatus(),
            a.getLatitude(),
            a.getLongitude(),
            a.getUpdatedAt()
        );
    }
}
