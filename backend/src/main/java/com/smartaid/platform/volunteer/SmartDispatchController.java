package com.smartaid.platform.volunteer;

import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentService;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/smart-dispatch")
public class SmartDispatchController {
    private final IncidentService incidents;
    private final VolunteerProfileRepository volunteers;
    private final VolunteerCertificationRepository certifications;
    private final VolunteerSkillRepository skills;
    private final SmartDispatchService dispatch;
    public SmartDispatchController(IncidentService incidents, VolunteerProfileRepository volunteers, VolunteerCertificationRepository certifications, VolunteerSkillRepository skills, SmartDispatchService dispatch) {
        this.incidents = incidents; this.volunteers = volunteers; this.certifications = certifications; this.skills = skills; this.dispatch = dispatch;
    }
    @GetMapping("/incidents/{incidentId}/recommendations")
    @PreAuthorize("hasAnyRole('EMS','ADMIN')")
    List<SmartDispatchService.DispatchRecommendation> recommendations(@PathVariable java.util.UUID incidentId) {
        Incident incident = incidents.find(incidentId);
        Set<String> requiredSkills = SmartDispatchService.requiredSkillsFor(incident.getEmergencyType().getCode());
        List<SmartDispatchService.ResponderCandidate> candidates = volunteers.findByAvailableTrueAndVerifiedTrue().stream()
                .filter(v -> v.getLatitude() != null && v.getLongitude() != null)
                .map(v -> new SmartDispatchService.ResponderCandidate(v.getUserId(), v.isVerified(), v.isAvailable(), certifications.hasValidCertification(v.getUserId(), Instant.now()), v.getLatitude(), v.getLongitude(), Set.copyOf(skills.findSkillCodes(v.getUserId()))))
                .toList();
        return dispatch.rank(incident.getLatitude(), incident.getLongitude(), requiredSkills, candidates);
    }
}
