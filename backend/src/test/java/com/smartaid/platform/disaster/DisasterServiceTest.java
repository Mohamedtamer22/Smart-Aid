package com.smartaid.platform.disaster;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.incident.EmergencyType;
import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.notification.NotificationService;
import com.smartaid.platform.notification.NotificationType;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DisasterServiceTest {
    private IncidentRepository incidents;
    private AuditService audit;
    private NotificationService notifications;
    private DisasterService service;

    @BeforeEach
    void setUp() {
        incidents = mock(IncidentRepository.class);
        audit = mock(AuditService.class);
        notifications = mock(NotificationService.class);
        service = new DisasterService(incidents, audit, notifications);
    }

    @Test
    void initial_state_is_inactive() {
        when(incidents.countByStatusIn(anyList())).thenReturn(0L);
        DisasterDtos.DisasterStatus status = service.getStatus();
        assertFalse(status.active());
        assertEquals("NONE", status.disasterType());
        assertEquals("NORMAL", status.disasterLevel());
    }

    @Test
    void activate_switches_mode_and_broadcasts_alert() {
        UUID actorId = UUID.randomUUID();
        when(incidents.countByStatusIn(anyList())).thenReturn(5L);

        DisasterDtos.ActivateDisasterRequest req = new DisasterDtos.ActivateDisasterRequest(
            "MASS_CASUALTY", "TIER_3", "Downtown Zone 4", 30.0, 31.0, 5.0, "Test activation"
        );
        DisasterDtos.DisasterStatus status = service.activate(actorId, req);

        assertTrue(status.active());
        assertEquals("MASS_CASUALTY", status.disasterType());
        assertEquals("TIER_3", status.disasterLevel());
        assertEquals("Downtown Zone 4", status.affectedArea());
        assertNotNull(status.activatedAt());

        verify(audit).record(eq(actorId), eq("DISASTER_MODE_ACTIVATED"), eq("DISASTER"), any(), any());
        verify(notifications).broadcast(eq(NotificationType.SYSTEM), anyString(), anyString());

        // Deactivate
        DisasterDtos.DisasterStatus deactivated = service.deactivate(actorId);
        assertFalse(deactivated.active());
        verify(audit).record(eq(actorId), eq("DISASTER_MODE_DEACTIVATED"), eq("DISASTER"), any(), any());
    }

    @Test
    void getOverview_aggregates_triage_categories() {
        EmergencyType cardiac = new EmergencyType("CARDIAC", "Cardiac Arrest");
        EmergencyType trauma = new EmergencyType("TRAUMA", "Severe Trauma");
        EmergencyType minor = new EmergencyType("FAINTING", "Fainting");

        Incident criticalInc = new Incident(UUID.randomUUID(), cardiac, 30.0, 31.0, "Critical patient", "CRITICAL");
        Incident highInc = new Incident(UUID.randomUUID(), trauma, 30.1, 31.1, "High priority patient", "HIGH");
        Incident lowInc = new Incident(UUID.randomUUID(), minor, 30.2, 31.2, "Walking patient", "LOW");

        when(incidents.countByStatusIn(anyList())).thenReturn(3L);
        when(incidents.findByStatusInOrderByCreatedAtDesc(anyList())).thenReturn(List.of(criticalInc, highInc, lowInc));

        DisasterDtos.DisasterOverview overview = service.getOverview();
        assertEquals(1, overview.redCount());
        assertEquals(1, overview.yellowCount());
        assertEquals(1, overview.greenCount());
        assertEquals(0, overview.blackCount());
        assertEquals(3, overview.priorityQueue().size());
        assertEquals("RED", overview.priorityQueue().get(0).triageTag());
    }
}
