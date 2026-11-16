package com.smartaid.platform.volunteer;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.config.DispatchProperties;
import com.smartaid.platform.exception.ApiException;
import com.smartaid.platform.incident.EmergencyType;
import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.incident.IncidentService;
import com.smartaid.platform.incident.IncidentStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class VolunteerMultiResponderTest {
    private VolunteerProfileRepository profiles;
    private VolunteerCertificationRepository certifications;
    private VolunteerSkillRepository skills;
    private EmergencyResponseRepository responses;
    private IncidentRepository incidents;
    private IncidentService incidentService;
    private AuditService audit;
    private VolunteerService volunteerService;

    private UUID incidentId;
    private Incident incident;
    private EmergencyType emergencyType;

    @BeforeEach
    void setUp() {
        profiles = mock(VolunteerProfileRepository.class);
        certifications = mock(VolunteerCertificationRepository.class);
        skills = mock(VolunteerSkillRepository.class);
        responses = mock(EmergencyResponseRepository.class);
        incidents = mock(IncidentRepository.class);
        incidentService = mock(IncidentService.class);
        audit = mock(AuditService.class);

        volunteerService = new VolunteerService(
            profiles,
            certifications,
            skills,
            responses,
            incidents,
            incidentService,
            audit,
            new DispatchProperties(15.0)
        );

        incidentId = UUID.randomUUID();
        emergencyType = new EmergencyType("MEDICAL", "Medical Emergency");
        incident = new Incident(UUID.randomUUID(), emergencyType, 30.0444, 31.2357, "Medical distress", "HIGH");
        incident.setId(incidentId);
        incident.moveTo(IncidentStatus.SEARCHING);

        when(incidents.findById(incidentId)).thenReturn(Optional.of(incident));
        when(incidents.findByIdForUpdate(incidentId)).thenReturn(Optional.of(incident));
        when(responses.save(any(EmergencyResponse.class))).thenAnswer(invocation -> {
            EmergencyResponse r = invocation.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });
    }

    private VolunteerProfile createEligibleVolunteer(UUID volunteerId) {
        VolunteerProfile profile = new VolunteerProfile(volunteerId);
        profile.setVerified(true);
        profile.setAvailable(true);
        profile.updateLocation(30.0450, 31.2360);

        when(profiles.findById(volunteerId)).thenReturn(Optional.of(profile));
        when(certifications.hasValidCertification(eq(volunteerId), any())).thenReturn(true);
        when(skills.findSkillCodes(volunteerId)).thenReturn(List.of("CPR", "AED", "FIRST_AID"));
        when(responses.findFirstByVolunteerIdAndResponseStatusInOrderByCreatedAtDesc(eq(volunteerId), any()))
            .thenReturn(Optional.empty());

        return profile;
    }

    @Test
    @DisplayName("First volunteer acceptance allocates PRIMARY_RESPONSE task and updates incident status")
    void firstResponder_assignedPrimaryResponseTask() {
        UUID volunteer1 = UUID.randomUUID();
        createEligibleVolunteer(volunteer1);

        when(responses.countByIncidentIdAndResponseStatusIn(eq(incidentId), any())).thenReturn(0L);
        when(responses.existsByIncidentIdAndVolunteerId(incidentId, volunteer1)).thenReturn(false);

        VolunteerDtos.MissionResponse response = volunteerService.accept(volunteer1, incidentId);

        assertNotNull(response);
        assertEquals("ACCEPTED", response.status());
        assertEquals("PRIMARY_RESPONSE", response.taskType());
        assertEquals("Multi-responder task: PRIMARY_RESPONSE", response.taskNotes());
        verify(incidentService).assignResponder(incident, volunteer1);
        verify(audit).record(eq(volunteer1), eq("EMERGENCY_RESPONSE_ACCEPTED"), eq("EMERGENCY_RESPONSE"), any());
    }

    @Test
    @DisplayName("Second volunteer acceptance allocates TRIAGE_CPR_SUPPORT task")
    void secondResponder_assignedTriageCprSupportTask() {
        incident.moveTo(IncidentStatus.RESPONDER_ASSIGNED);
        UUID volunteer2 = UUID.randomUUID();
        createEligibleVolunteer(volunteer2);

        when(responses.countByIncidentIdAndResponseStatusIn(eq(incidentId), any())).thenReturn(1L);
        when(responses.existsByIncidentIdAndVolunteerId(incidentId, volunteer2)).thenReturn(false);

        VolunteerDtos.MissionResponse response = volunteerService.accept(volunteer2, incidentId);

        assertNotNull(response);
        assertEquals("ACCEPTED", response.status());
        assertEquals("TRIAGE_CPR_SUPPORT", response.taskType());
        assertEquals("Multi-responder task: TRIAGE_CPR_SUPPORT", response.taskNotes());
        verify(incidentService, never()).assignResponder(any(), any());
    }

    @Test
    @DisplayName("Third volunteer acceptance allocates AED_CROWD_CONTROL task")
    void thirdResponder_assignedAedCrowdControlTask() {
        incident.moveTo(IncidentStatus.RESPONDER_ASSIGNED);
        UUID volunteer3 = UUID.randomUUID();
        createEligibleVolunteer(volunteer3);

        when(responses.countByIncidentIdAndResponseStatusIn(eq(incidentId), any())).thenReturn(2L);
        when(responses.existsByIncidentIdAndVolunteerId(incidentId, volunteer3)).thenReturn(false);

        VolunteerDtos.MissionResponse response = volunteerService.accept(volunteer3, incidentId);

        assertNotNull(response);
        assertEquals("ACCEPTED", response.status());
        assertEquals("AED_CROWD_CONTROL", response.taskType());
        assertEquals("Multi-responder task: AED_CROWD_CONTROL", response.taskNotes());
        verify(incidentService, never()).assignResponder(any(), any());
    }

    @Test
    @DisplayName("Fourth volunteer is rejected with 409 MAX_RESPONDERS_ASSIGNED when 3 responders already assigned")
    void fourthResponder_rejectedWithMaxRespondersAssigned() {
        incident.moveTo(IncidentStatus.RESPONDER_ASSIGNED);
        UUID volunteer4 = UUID.randomUUID();
        createEligibleVolunteer(volunteer4);

        when(responses.countByIncidentIdAndResponseStatusIn(eq(incidentId), any())).thenReturn(3L);
        when(responses.existsByIncidentIdAndVolunteerId(incidentId, volunteer4)).thenReturn(false);

        ApiException ex = assertThrows(ApiException.class, () -> volunteerService.accept(volunteer4, incidentId));
        assertEquals(HttpStatus.CONFLICT, ex.status());
        assertEquals("MAX_RESPONDERS_ASSIGNED", ex.code());
        assertEquals("Maximum responders already assigned to this incident", ex.getMessage());
    }

    @Test
    @DisplayName("Duplicate volunteer acceptance on same incident is rejected with 409 INCIDENT_UNAVAILABLE")
    void duplicateVolunteerAccept_rejectedWithIncidentUnavailable() {
        UUID volunteer1 = UUID.randomUUID();
        createEligibleVolunteer(volunteer1);

        when(responses.existsByIncidentIdAndVolunteerId(incidentId, volunteer1)).thenReturn(true);

        ApiException ex = assertThrows(ApiException.class, () -> volunteerService.accept(volunteer1, incidentId));
        assertEquals(HttpStatus.CONFLICT, ex.status());
        assertEquals("INCIDENT_UNAVAILABLE", ex.code());
    }

    @Test
    @DisplayName("Volunteer with existing active mission is rejected with 409 ACTIVE_MISSION")
    void volunteerWithActiveMission_rejected() {
        UUID volunteerId = UUID.randomUUID();
        createEligibleVolunteer(volunteerId);

        EmergencyResponse activeResponse = new EmergencyResponse(UUID.randomUUID(), volunteerId, 5);
        when(responses.findFirstByVolunteerIdAndResponseStatusInOrderByCreatedAtDesc(eq(volunteerId), any()))
            .thenReturn(Optional.of(activeResponse));

        ApiException ex = assertThrows(ApiException.class, () -> volunteerService.accept(volunteerId, incidentId));
        assertEquals(HttpStatus.CONFLICT, ex.status());
        assertEquals("ACTIVE_MISSION", ex.code());
    }

    @Test
    @DisplayName("Volunteer lacking required skills is rejected with 403 SKILL_MISMATCH")
    void volunteerSkillMismatch_rejected() {
        EmergencyType cardiacType = new EmergencyType("CARDIAC", "Cardiac Arrest");
        Incident cardiacIncident = new Incident(UUID.randomUUID(), cardiacType, 30.0444, 31.2357, "Cardiac arrest", "CRITICAL");
        cardiacIncident.setId(incidentId);
        cardiacIncident.moveTo(IncidentStatus.SEARCHING);
        when(incidents.findByIdForUpdate(incidentId)).thenReturn(Optional.of(cardiacIncident));

        UUID volunteerId = UUID.randomUUID();
        createEligibleVolunteer(volunteerId);
        // Only has FIRST_AID, missing CPR and AED
        when(skills.findSkillCodes(volunteerId)).thenReturn(List.of("FIRST_AID"));
        when(responses.countByIncidentIdAndResponseStatusIn(eq(incidentId), any())).thenReturn(0L);
        when(responses.existsByIncidentIdAndVolunteerId(incidentId, volunteerId)).thenReturn(false);

        ApiException ex = assertThrows(ApiException.class, () -> volunteerService.accept(volunteerId, incidentId));
        assertEquals(HttpStatus.FORBIDDEN, ex.status());
        assertEquals("SKILL_MISMATCH", ex.code());
    }
}
