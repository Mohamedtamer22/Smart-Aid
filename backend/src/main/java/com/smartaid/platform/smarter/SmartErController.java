package com.smartaid.platform.smarter;

import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentService;
import com.smartaid.platform.volunteer.SmartDispatchService;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/smart-er")
public class SmartErController {
    private final IncidentService incidents;
    private final HospitalRepository hospitals;
    private final HospitalCapabilityRepository capabilities;
    private final SmartErService smartEr;
    public SmartErController(IncidentService incidents, HospitalRepository hospitals, HospitalCapabilityRepository capabilities, SmartErService smartEr) {
        this.incidents = incidents; this.hospitals = hospitals; this.capabilities = capabilities; this.smartEr = smartEr;
    }
    @GetMapping("/incidents/{incidentId}/recommendations")
    @PreAuthorize("hasAnyRole('EMS','ADMIN')")
    List<SmartErService.HospitalRecommendation> recommendations(@PathVariable java.util.UUID incidentId) {
        return rank(incidentId);
    }
    /** Compatibility route for the documented Smart ER API contract. */
    @GetMapping("/{incidentId}")
    @PreAuthorize("hasAnyRole('EMS','ADMIN')")
    List<SmartErService.HospitalRecommendation> recommendationsByIncident(@PathVariable java.util.UUID incidentId) {
        return rank(incidentId);
    }
    private List<SmartErService.HospitalRecommendation> rank(java.util.UUID incidentId) {
        Incident incident = incidents.find(incidentId);
        Requirement requirement = requirementFor(incident.getEmergencyType().getCode());
        List<SmartErService.HospitalCandidate> candidates = hospitals.findByVerifiedTrue().stream().map(hospital -> {
            double km = SmartDispatchService.haversineKm(incident.getLatitude(), incident.getLongitude(), hospital.getLatitude(), hospital.getLongitude());
            int eta = Math.max(1, (int) Math.ceil(km / 0.65)); // 39 km/h transparent development estimate, not a traffic route
            return new SmartErService.HospitalCandidate(hospital.getId(), hospital.getName(), hospital.isVerified(), eta,
                    capabilities.hasSpecialty(hospital.getId(), requirement.specialty()), capabilities.hasAvailableResource(hospital.getId(), requirement.resource()), hospital.getEstimatedCongestion());
        }).toList();
        return smartEr.rank(candidates);
    }
    private Requirement requirementFor(String emergencyType) {
        return switch (emergencyType) {
            case "CARDIAC" -> new Requirement("CARDIOLOGY", "CATH_LAB");
            case "TRAUMA", "ACCIDENT" -> new Requirement("TRAUMA", "TRAUMA_BAY");
            default -> new Requirement("EMERGENCY", "EMERGENCY_BAY");
        };
    }
    private record Requirement(String specialty, String resource) { }
}
