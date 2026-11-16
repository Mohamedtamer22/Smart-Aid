package com.smartaid.platform.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.smartaid.platform.audit.AuditLogRepository;
import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.auth.RoleRepository;
import com.smartaid.platform.auth.UserAccountRepository;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.resource.AedDeviceRepository;
import com.smartaid.platform.resource.AmbulanceRepository;
import com.smartaid.platform.smarter.HospitalRepository;
import com.smartaid.platform.volunteer.VolunteerProfile;
import com.smartaid.platform.volunteer.VolunteerProfileRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class AdminServiceTest {
    private UserAccountRepository users;
    private RoleRepository roles;
    private VolunteerProfileRepository volunteers;
    private IncidentRepository incidents;
    private HospitalRepository hospitals;
    private AmbulanceRepository ambulances;
    private AedDeviceRepository aeds;
    private AuditLogRepository auditLogs;
    private AuditService audit;
    private JdbcTemplate jdbc;
    private AdminService service;

    @BeforeEach
    void setUp() {
        users = mock(UserAccountRepository.class);
        roles = mock(RoleRepository.class);
        volunteers = mock(VolunteerProfileRepository.class);
        incidents = mock(IncidentRepository.class);
        hospitals = mock(HospitalRepository.class);
        ambulances = mock(AmbulanceRepository.class);
        aeds = mock(AedDeviceRepository.class);
        auditLogs = mock(AuditLogRepository.class);
        audit = mock(AuditService.class);
        jdbc = mock(JdbcTemplate.class);

        service = new AdminService(users, roles, volunteers, incidents, hospitals, ambulances, aeds, auditLogs, audit, jdbc);
    }

    @Test
    void getOverview_aggregates_system_entity_counts() {
        when(users.count()).thenReturn(25L);
        when(volunteers.count()).thenReturn(10L);
        when(volunteers.countByVerifiedFalse()).thenReturn(3L);
        when(hospitals.count()).thenReturn(4L);
        when(ambulances.count()).thenReturn(6L);
        when(aeds.count()).thenReturn(15L);
        when(incidents.countByStatusIn(any())).thenReturn(2L);

        AdminDtos.SystemOverview overview = service.getOverview();
        assertEquals(25L, overview.totalUsers());
        assertEquals(10L, overview.totalVolunteers());
        assertEquals(3L, overview.pendingVolunteerVerifications());
        assertEquals(4L, overview.totalHospitals());
        assertEquals(6L, overview.totalAmbulances());
        assertEquals(15L, overview.totalAeds());
        assertEquals(2L, overview.activeIncidents());
    }

    @Test
    void verifyVolunteer_updates_profile_and_audits_action() {
        UUID adminId = UUID.randomUUID();
        UUID volunteerId = UUID.randomUUID();
        VolunteerProfile profile = new VolunteerProfile(volunteerId);
        profile.setVerified(false);
        profile.setAvailable(true);

        when(volunteers.findById(volunteerId)).thenReturn(Optional.of(profile));

        service.verifyVolunteer(adminId, volunteerId);

        assertTrue(profile.isVerified());
        verify(volunteers).save(profile);
        verify(audit).record(eq(adminId), eq("VOLUNTEER_VERIFIED"), eq("VOLUNTEER_PROFILE"), eq(volunteerId), any());
    }
}
