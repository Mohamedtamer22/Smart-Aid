package com.smartaid.platform.volunteer;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
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
@RequestMapping("/api/volunteers")
public class VolunteerController {
    private final VolunteerService volunteers;

    public VolunteerController(VolunteerService volunteers) {
        this.volunteers = volunteers;
    }

    @PostMapping("/me/onboarding")
    @PreAuthorize("isAuthenticated()")
    VolunteerDtos.VolunteerProfileResponse startOnboarding(Authentication authentication) {
        return volunteers.startOnboarding(userId(authentication));
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('VOLUNTEER')")
    VolunteerDtos.VolunteerProfileResponse profile(Authentication authentication) {
        return volunteers.profile(userId(authentication));
    }

    @PutMapping("/me/availability")
    @PreAuthorize("hasRole('VOLUNTEER')")
    VolunteerDtos.VolunteerProfileResponse availability(@Valid @RequestBody VolunteerDtos.AvailabilityRequest request,
                                                         Authentication authentication) {
        return volunteers.updateAvailability(userId(authentication), request.available());
    }

    @PutMapping("/me/location")
    @PreAuthorize("hasRole('VOLUNTEER')")
    VolunteerDtos.VolunteerProfileResponse location(@Valid @RequestBody VolunteerDtos.Coordinates request,
                                                     Authentication authentication) {
        return volunteers.updateLocation(userId(authentication), request);
    }

    @GetMapping("/dashboard")
    @PreAuthorize("hasRole('VOLUNTEER')")
    VolunteerDtos.VolunteerDashboardResponse dashboard(Authentication authentication) {
        return volunteers.dashboard(userId(authentication));
    }

    @GetMapping("/incidents/nearby")
    @PreAuthorize("hasRole('VOLUNTEER')")
    List<VolunteerDtos.NearbyIncidentResponse> nearby(Authentication authentication) {
        return volunteers.nearbyIncidents(userId(authentication));
    }

    @PostMapping("/incidents/{incidentId}/accept")
    @PreAuthorize("hasRole('VOLUNTEER')")
    VolunteerDtos.MissionResponse accept(@PathVariable UUID incidentId, Authentication authentication) {
        return volunteers.accept(userId(authentication), incidentId);
    }

    @GetMapping("/missions/active")
    @PreAuthorize("hasRole('VOLUNTEER')")
    VolunteerDtos.MissionResponse activeMission(Authentication authentication) {
        return volunteers.activeMission(userId(authentication));
    }

    @PatchMapping("/missions/{missionId}")
    @PreAuthorize("hasRole('VOLUNTEER')")
    VolunteerDtos.MissionResponse updateMission(@PathVariable UUID missionId,
                                                @Valid @RequestBody VolunteerDtos.UpdateMissionRequest request,
                                                Authentication authentication) {
        return volunteers.updateMission(userId(authentication), missionId, request.status());
    }

    private UUID userId(Authentication authentication) {
        return (UUID) authentication.getPrincipal();
    }
}
