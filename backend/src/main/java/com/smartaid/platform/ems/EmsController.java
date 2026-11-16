package com.smartaid.platform.ems;

import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ems")
@PreAuthorize("hasAnyRole('EMS','ADMIN')")
public class EmsController {
    private final EmsService ems;

    public EmsController(EmsService ems) {
        this.ems = ems;
    }

    @GetMapping("/dashboard")
    EmsDtos.DashboardResponse dashboard() {
        return ems.dashboard();
    }

    @GetMapping("/incidents/{incidentId}")
    EmsDtos.IncidentDetail incident(@PathVariable UUID incidentId) {
        return ems.incident(incidentId);
    }

    @PostMapping("/incidents/{incidentId}/assign")
    EmsDtos.IncidentDetail assign(@PathVariable UUID incidentId, Authentication authentication) {
        return ems.assign((UUID) authentication.getPrincipal(), incidentId);
    }
}
