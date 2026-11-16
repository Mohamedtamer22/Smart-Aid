package com.smartaid.platform.ems;

import com.smartaid.platform.exception.ApiException;
import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentDtos;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.incident.IncidentService;
import com.smartaid.platform.incident.IncidentStatus;
import com.smartaid.platform.incident.IncidentStatusHistoryRepository;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EmsService {
    private final IncidentRepository incidents;
    private final IncidentStatusHistoryRepository history;
    private final IncidentService incidentService;

    public EmsService(IncidentRepository incidents, IncidentStatusHistoryRepository history, IncidentService incidentService) {
        this.incidents = incidents;
        this.history = history;
        this.incidentService = incidentService;
    }

    @Transactional(readOnly = true)
    public EmsDtos.DashboardResponse dashboard() {
        List<Incident> active = incidents.findByStatusInOrderByCreatedAtDesc(Arrays.stream(IncidentStatus.values())
                .filter(status -> !status.isTerminal()).toList());
        int critical = (int) active.stream().filter(incident -> "CRITICAL".equals(incident.getPriority())).count();
        return new EmsDtos.DashboardResponse(active.size(), critical, active.stream().map(this::toSummary).toList());
    }

    @Transactional(readOnly = true)
    public EmsDtos.IncidentDetail incident(UUID incidentId) {
        Incident incident = incidents.findById(incidentId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "INCIDENT_NOT_FOUND", "Incident was not found"));
        List<EmsDtos.TimelineEvent> timeline = history.findByIncidentIdOrderByCreatedAtAsc(incidentId).stream()
                .map(event -> new EmsDtos.TimelineEvent(event.getFromStatus() == null ? null : event.getFromStatus().name(),
                        event.getToStatus().name(), event.getReason(), event.getCreatedAt()))
                .toList();
        return new EmsDtos.IncidentDetail(toSummary(incident), incident.getNotes(), timeline);
    }

    @Transactional
    public EmsDtos.IncidentDetail assign(UUID emsUserId, UUID incidentId) {
        Incident incident = incidents.findByIdForUpdate(incidentId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "INCIDENT_NOT_FOUND", "Incident was not found"));
        incidentService.assignEms(incident, emsUserId);
        return incident(incidentId);
    }

    private EmsDtos.IncidentSummary toSummary(Incident incident) {
        return new EmsDtos.IncidentSummary(incident.getId().toString(), incident.getEmergencyType().getCode(), incident.getStatus().name(),
                incident.getPriority(), new IncidentDtos.Location(incident.getLatitude(), incident.getLongitude()), incident.getCreatedAt());
    }
}
