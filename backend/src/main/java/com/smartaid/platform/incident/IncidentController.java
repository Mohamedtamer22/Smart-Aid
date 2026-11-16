package com.smartaid.platform.incident;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/incidents")
public class IncidentController {
    private final IncidentService service;
    private final com.smartaid.platform.volunteer.VolunteerService volunteerService;

    public IncidentController(IncidentService service, com.smartaid.platform.volunteer.VolunteerService volunteerService) {
        this.service = service;
        this.volunteerService = volunteerService;
    }

    @PostMapping ResponseEntity<IncidentDtos.IncidentResponse> create(@Valid @RequestBody IncidentDtos.CreateIncidentRequest request,
                                                                        @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
                                                                        Authentication authentication) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createManual(userId(authentication), request, idempotencyKey));
    }

    @GetMapping("/mine") List<IncidentDtos.IncidentResponse> mine(Authentication authentication) { return service.mine(userId(authentication)); }

    /** Compatibility alias for GET /api/incidents/my */
    @GetMapping("/my") List<IncidentDtos.IncidentResponse> my(Authentication authentication) { return mine(authentication); }

    @GetMapping("/{id}") IncidentDtos.IncidentDetailResponse detail(@PathVariable UUID id, Authentication authentication) {
        boolean canCoordinate = authentication.getAuthorities().stream().map(GrantedAuthority::getAuthority).anyMatch(role -> role.equals("ROLE_EMS") || role.equals("ROLE_ADMIN"));
        return service.detail(userId(authentication), canCoordinate, id);
    }

    @PatchMapping("/{id}/status") IncidentDtos.IncidentResponse changeStatus(@PathVariable UUID id, @Valid @RequestBody IncidentDtos.ChangeStatusRequest request, Authentication authentication) {
        boolean canCoordinate = authentication.getAuthorities().stream().map(GrantedAuthority::getAuthority).anyMatch(role -> role.equals("ROLE_EMS") || role.equals("ROLE_ADMIN"));
        return service.changeStatus(userId(authentication), canCoordinate, id, request);
    }

    /** Compatibility alias for POST /api/incidents/{id}/status */
    @PostMapping("/{id}/status") IncidentDtos.IncidentResponse postStatus(@PathVariable UUID id, @Valid @RequestBody IncidentDtos.ChangeStatusRequest request, Authentication authentication) {
        return changeStatus(id, request, authentication);
    }

    /** Compatibility alias for POST /api/incidents/{id}/accept */
    @PostMapping("/{id}/accept")
    public com.smartaid.platform.volunteer.VolunteerDtos.MissionResponse acceptIncident(@PathVariable UUID id, Authentication authentication) {
        return volunteerService.accept(userId(authentication), id);
    }

    private UUID userId(Authentication authentication) { return (UUID) authentication.getPrincipal(); }
}
