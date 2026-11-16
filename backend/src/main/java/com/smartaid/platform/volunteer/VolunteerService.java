package com.smartaid.platform.volunteer;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.config.DispatchProperties;
import com.smartaid.platform.exception.ApiException;
import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.incident.IncidentService;
import com.smartaid.platform.incident.IncidentStatus;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VolunteerService {
    private static final double DEVELOPMENT_SPEED_KM_PER_MINUTE = 0.5;

    private final VolunteerProfileRepository profiles;
    private final VolunteerCertificationRepository certifications;
    private final VolunteerSkillRepository skills;
    private final EmergencyResponseRepository responses;
    private final IncidentRepository incidents;
    private final IncidentService incidentService;
    private final AuditService audit;
    private final DispatchProperties dispatchProperties;

    public VolunteerService(VolunteerProfileRepository profiles, VolunteerCertificationRepository certifications,
            VolunteerSkillRepository skills, EmergencyResponseRepository responses, IncidentRepository incidents,
            IncidentService incidentService, AuditService audit, DispatchProperties dispatchProperties) {
        this.profiles = profiles;
        this.certifications = certifications;
        this.skills = skills;
        this.responses = responses;
        this.incidents = incidents;
        this.incidentService = incidentService;
        this.audit = audit;
        this.dispatchProperties = dispatchProperties;
    }

    @Transactional
    public VolunteerDtos.VolunteerProfileResponse startOnboarding(UUID userId) {
        VolunteerProfile profile = profiles.findById(userId).orElseGet(() -> {
            VolunteerProfile created = profiles.save(new VolunteerProfile(userId));
            audit.record(userId, "VOLUNTEER_PROFILE_REQUESTED", "VOLUNTEER_PROFILE", userId);
            return created;
        });
        return toProfile(profile);
    }

    @Transactional(readOnly = true)
    public VolunteerDtos.VolunteerProfileResponse profile(UUID userId) {
        return toProfile(requireProfile(userId));
    }

    @Transactional
    public VolunteerDtos.VolunteerProfileResponse updateAvailability(UUID userId, boolean available) {
        VolunteerProfile profile = requireProfile(userId);
        if (!available && activeResponse(userId).isPresent()) {
            throw new ApiException(HttpStatus.CONFLICT, "ACTIVE_MISSION", "You cannot become unavailable while an active mission is assigned");
        }
        profile.setAvailable(available);
        audit.record(userId, available ? "VOLUNTEER_AVAILABLE" : "VOLUNTEER_UNAVAILABLE", "VOLUNTEER_PROFILE", userId);
        return toProfile(profile);
    }

    @Transactional
    public VolunteerDtos.VolunteerProfileResponse updateLocation(UUID userId, VolunteerDtos.Coordinates location) {
        VolunteerProfile profile = requireProfile(userId);
        profile.updateLocation(location.latitude(), location.longitude());
        audit.record(userId, "VOLUNTEER_LOCATION_UPDATED", "VOLUNTEER_PROFILE", userId);
        return toProfile(profile);
    }

    @Transactional(readOnly = true)
    public VolunteerDtos.VolunteerDashboardResponse dashboard(UUID userId) {
        VolunteerProfile profile = requireProfile(userId);
        VolunteerDtos.MissionResponse mission = activeResponse(userId).map(this::toMission).orElse(null);
        Set<String> volunteerSkills = Set.copyOf(skills.findSkillCodes(userId));
        int nearbyCount = eligible(profile) ? (int) nearby(profile).stream()
                .filter(incident -> volunteerSkills.containsAll(SmartDispatchService.requiredSkillsFor(incident.getEmergencyType().getCode())))
                .count() : 0;
        return new VolunteerDtos.VolunteerDashboardResponse(toProfile(profile), mission, nearbyCount);
    }

    @Transactional(readOnly = true)
    public List<VolunteerDtos.NearbyIncidentResponse> nearbyIncidents(UUID userId) {
        VolunteerProfile profile = requireProfile(userId);
        if (!eligible(profile)) {
            throw new ApiException(HttpStatus.CONFLICT, "VOLUNTEER_NOT_READY",
                    "A verified, available profile with a valid certification and location is required");
        }
        Set<String> volunteerSkills = Set.copyOf(skills.findSkillCodes(userId));
        return nearby(profile).stream().filter(incident -> volunteerSkills.containsAll(SmartDispatchService.requiredSkillsFor(incident.getEmergencyType().getCode())))
                .map(incident -> nearbyResponse(incident, profile, volunteerSkills)).toList();
    }

    @Transactional
    public VolunteerDtos.MissionResponse accept(UUID userId, UUID incidentId) {
        VolunteerProfile profile = requireProfile(userId);
        if (!eligible(profile)) {
            throw new ApiException(HttpStatus.CONFLICT, "VOLUNTEER_NOT_READY",
                    "A verified, available profile with a valid certification and location is required");
        }
        if (activeResponse(userId).isPresent()) {
            throw new ApiException(HttpStatus.CONFLICT, "ACTIVE_MISSION", "Complete or cancel the active mission before accepting another incident");
        }
        Incident incident = incidents.findByIdForUpdate(incidentId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "INCIDENT_NOT_FOUND", "Incident was not found"));
        if ((incident.getStatus() != IncidentStatus.SEARCHING && incident.getStatus() != IncidentStatus.RESPONDER_ASSIGNED)
                || responses.existsByIncidentIdAndVolunteerId(incidentId, userId)) {
            throw new ApiException(HttpStatus.CONFLICT, "INCIDENT_UNAVAILABLE", "This incident is no longer available for response");
        }
        long activeOnIncident = responses.countByIncidentIdAndResponseStatusIn(incidentId, List.of(MissionStatus.ACCEPTED, MissionStatus.ARRIVED));
        if (activeOnIncident >= 3) {
            throw new ApiException(HttpStatus.CONFLICT, "MAX_RESPONDERS_ASSIGNED", "Maximum responders already assigned to this incident");
        }
        Set<String> volunteerSkills = Set.copyOf(skills.findSkillCodes(userId));
        if (!volunteerSkills.containsAll(SmartDispatchService.requiredSkillsFor(incident.getEmergencyType().getCode()))) {
            throw new ApiException(HttpStatus.FORBIDDEN, "SKILL_MISMATCH", "Your verified skills do not meet this incident's response requirement");
        }
        int eta = estimateEta(profile.getLatitude(), profile.getLongitude(), incident.getLatitude(), incident.getLongitude());
        String taskType = activeOnIncident == 0 ? "PRIMARY_RESPONSE" : (activeOnIncident == 1 ? "TRIAGE_CPR_SUPPORT" : "AED_CROWD_CONTROL");
        EmergencyResponse response = responses.save(new EmergencyResponse(incidentId, userId, eta, taskType, "Multi-responder task: " + taskType));
        if (incident.getStatus() == IncidentStatus.SEARCHING) {
            incidentService.assignResponder(incident, userId);
        }
        audit.record(userId, "EMERGENCY_RESPONSE_ACCEPTED", "EMERGENCY_RESPONSE", response.getId());
        return toMission(response);
    }

    @Transactional(readOnly = true)
    public VolunteerDtos.MissionResponse activeMission(UUID userId) {
        return activeResponse(userId).map(this::toMission)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "NO_ACTIVE_MISSION", "No active volunteer mission was found"));
    }

    @Transactional
    public VolunteerDtos.MissionResponse updateMission(UUID userId, UUID missionId, MissionStatus nextStatus) {
        EmergencyResponse response = responses.findById(missionId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "MISSION_NOT_FOUND", "Volunteer mission was not found"));
        if (!response.getVolunteerId().equals(userId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ACCESS_DENIED", "You are not allowed to update this mission");
        }
        response.moveTo(nextStatus);
        audit.record(userId, "VOLUNTEER_MISSION_" + nextStatus.name(), "EMERGENCY_RESPONSE", response.getId());
        return toMission(response);
    }

    private VolunteerProfile requireProfile(UUID userId) {
        return profiles.findById(userId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "VOLUNTEER_PROFILE_NOT_FOUND",
                "Complete volunteer onboarding before using volunteer features"));
    }

    private boolean eligible(VolunteerProfile profile) {
        return profile.isVerified() && profile.isAvailable() && profile.getLatitude() != null && profile.getLongitude() != null
                && certifications.hasValidCertification(profile.getUserId(), Instant.now());
    }

    private List<Incident> nearby(VolunteerProfile profile) {
        return incidents.findByStatusOrderByCreatedAtDesc(IncidentStatus.SEARCHING).stream()
                .filter(incident -> SmartDispatchService.haversineKm(profile.getLatitude(), profile.getLongitude(),
                        incident.getLatitude(), incident.getLongitude()) <= dispatchProperties.maximumRadiusKm())
                .toList();
    }

    private java.util.Optional<EmergencyResponse> activeResponse(UUID userId) {
        return responses.findFirstByVolunteerIdAndResponseStatusInOrderByCreatedAtDesc(userId,
                List.of(MissionStatus.ACCEPTED, MissionStatus.ARRIVED));
    }

    private VolunteerDtos.VolunteerProfileResponse toProfile(VolunteerProfile profile) {
        boolean certificationValid = certifications.hasValidCertification(profile.getUserId(), Instant.now());
        VolunteerDtos.Coordinates location = profile.getLatitude() == null ? null
                : new VolunteerDtos.Coordinates(profile.getLatitude(), profile.getLongitude());
        return new VolunteerDtos.VolunteerProfileResponse(profile.isVerified(), profile.isAvailable(), location, certificationValid,
                skills.findSkillCodes(profile.getUserId()).stream().sorted().toList(), eligible(profile));
    }

    private VolunteerDtos.NearbyIncidentResponse nearbyResponse(Incident incident, VolunteerProfile profile, Set<String> volunteerSkills) {
        double distance = SmartDispatchService.haversineKm(profile.getLatitude(), profile.getLongitude(), incident.getLatitude(), incident.getLongitude());
        List<String> matching = volunteerSkills.stream()
                .filter(SmartDispatchService.requiredSkillsFor(incident.getEmergencyType().getCode())::contains).sorted().toList();
        return new VolunteerDtos.NearbyIncidentResponse(toPreview(incident), round(distance),
                estimateEta(profile.getLatitude(), profile.getLongitude(), incident.getLatitude(), incident.getLongitude()), matching);
    }

    private VolunteerDtos.MissionResponse toMission(EmergencyResponse response) {
        Incident incident = incidents.findById(response.getIncidentId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "INCIDENT_NOT_FOUND", "Incident was not found"));
        return new VolunteerDtos.MissionResponse(response.getId().toString(), response.getResponseStatus().name(), response.getEtaMinutes(),
                toPreview(incident), response.getAcceptedAt(), response.getArrivedAt(), response.getCompletedAt(),
                response.getTaskType(), response.getTaskNotes());
    }

    private VolunteerDtos.IncidentPreview toPreview(Incident incident) {
        return new VolunteerDtos.IncidentPreview(incident.getId().toString(), incident.getEmergencyType().getCode(), incident.getPriority(),
                new VolunteerDtos.Coordinates(incident.getLatitude(), incident.getLongitude()), incident.getCreatedAt());
    }

    private int estimateEta(double fromLatitude, double fromLongitude, double toLatitude, double toLongitude) {
        return Math.max(1, (int) Math.ceil(SmartDispatchService.haversineKm(fromLatitude, fromLongitude, toLatitude, toLongitude)
                / DEVELOPMENT_SPEED_KM_PER_MINUTE));
    }

    private double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
