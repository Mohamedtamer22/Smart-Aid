package com.smartaid.platform.analytics;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.smartaid.platform.incident.EmergencyType;
import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.resource.AedDeviceRepository;
import com.smartaid.platform.resource.AmbulanceRepository;
import com.smartaid.platform.smarter.Hospital;
import com.smartaid.platform.smarter.HospitalCapabilityRepository;
import com.smartaid.platform.smarter.HospitalRepository;
import com.smartaid.platform.smarter.SmartErService;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class AnalyticsServiceTest {
    private IncidentRepository incidents;
    private HospitalRepository hospitals;
    private HospitalCapabilityRepository capabilities;
    private SmartErService smartEr;
    private AedDeviceRepository aeds;
    private AmbulanceRepository ambulances;
    private AnalyticsService service;

    @BeforeEach
    void setUp() {
        incidents = mock(IncidentRepository.class);
        hospitals = mock(HospitalRepository.class);
        capabilities = mock(HospitalCapabilityRepository.class);
        smartEr = mock(SmartErService.class);
        aeds = mock(AedDeviceRepository.class);
        ambulances = mock(AmbulanceRepository.class);
        service = new AnalyticsService(incidents, hospitals, capabilities, smartEr, aeds, ambulances);
    }

    @Test
    void getDashboard_returns_correct_kpis() {
        EmergencyType cardiac = new EmergencyType("CARDIAC", "Cardiac");
        Incident i1 = new Incident(UUID.randomUUID(), cardiac, 30.0, 31.0, null, "CRITICAL");
        i1.setId(UUID.randomUUID());

        when(incidents.findAll()).thenReturn(List.of(i1));
        when(hospitals.count()).thenReturn(5L);
        when(aeds.count()).thenReturn(12L);
        when(ambulances.findByStatus("AVAILABLE")).thenReturn(List.of());

        AnalyticsDtos.DashboardOverview dashboard = service.getDashboard();
        assertEquals(1, dashboard.totalIncidents());
        assertEquals(1, dashboard.activeIncidents());
        assertEquals(5, dashboard.totalHospitals());
        assertEquals(12, dashboard.totalAeds());
        assertTrue(dashboard.averageResponseTimeMinutes() > 0);
        assertTrue(dashboard.volunteerAcceptanceRatePercent() > 0);
    }

    @Test
    void runHospitalStrategiesComparison_generates_three_way_benchmark() {
        EmergencyType cardiac = new EmergencyType("CARDIAC", "Cardiac");
        Incident incident = new Incident(UUID.randomUUID(), cardiac, 30.0, 31.0, null, "CRITICAL");
        incident.setId(UUID.randomUUID());

        Hospital h1 = new Hospital("Central Hospital", 30.01, 31.01, true, 20);
        h1.setId(UUID.randomUUID());
        Hospital h2 = new Hospital("Regional Medical", 30.05, 31.05, true, 10);
        h2.setId(UUID.randomUUID());

        when(incidents.findAllByOrderByCreatedAtDesc()).thenReturn(List.of(incident));
        when(hospitals.findByVerifiedTrue()).thenReturn(List.of(h1, h2));
        when(capabilities.hasSpecialty(any(), any())).thenReturn(true);
        when(capabilities.hasAvailableResource(any(), any())).thenReturn(true);

        when(smartEr.rank(anyList())).thenReturn(List.of(
            new SmartErService.HospitalRecommendation(h1.getId(), h1.getName(), 92.5, 4, 85.0, 100.0, 100.0, 80.0, List.of("Verified specialty match"))
        ));

        AnalyticsDtos.ResearchReport report = service.runHospitalStrategiesComparison();
        assertNotNull(report);
        assertEquals(1, report.benchmarks().size());

        AnalyticsDtos.ResearchComparison trial = report.benchmarks().get(0);
        assertEquals("Nearest Hospital", trial.nearestHospital().strategyName());
        assertEquals("Random Suitable Hospital", trial.randomHospital().strategyName());
        assertEquals("Smart ER Recommendation", trial.smartErRecommendation().strategyName());
        assertTrue(trial.smartErRecommendation().compositeScore() > 0);
    }
}
