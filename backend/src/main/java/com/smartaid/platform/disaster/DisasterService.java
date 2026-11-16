package com.smartaid.platform.disaster;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.notification.NotificationService;
import com.smartaid.platform.notification.NotificationType;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DisasterService {
    private final IncidentRepository incidents;
    private final AuditService audit;
    private final NotificationService notifications;

    // In-memory operational disaster state
    private volatile boolean active = false;
    private volatile String disasterType = "NONE";
    private volatile String disasterLevel = "NORMAL";
    private volatile String affectedArea = "N/A";
    private volatile Instant activatedAt = null;

    // Explicit triage tags for incidents: incidentId -> TriageTag (RED, YELLOW, GREEN, BLACK)
    private final Map<UUID, String> triageTags = new ConcurrentHashMap<>();

    public DisasterService(IncidentRepository incidents, AuditService audit, NotificationService notifications) {
        this.incidents = incidents;
        this.audit = audit;
        this.notifications = notifications;
    }

    public DisasterDtos.DisasterStatus getStatus() {
        long activeCount = incidents.countByStatusIn(List.of(
            com.smartaid.platform.incident.IncidentStatus.NEW,
            com.smartaid.platform.incident.IncidentStatus.SEARCHING,
            com.smartaid.platform.incident.IncidentStatus.RESPONDER_ASSIGNED,
            com.smartaid.platform.incident.IncidentStatus.EMS_ASSIGNED,
            com.smartaid.platform.incident.IncidentStatus.IN_TRANSIT
        ));
        return new DisasterDtos.DisasterStatus(
            active,
            disasterType,
            disasterLevel,
            affectedArea,
            activatedAt,
            (int) activeCount,
            active ? 12 : 0 // Active mobilization count
        );
    }

    @Transactional
    public DisasterDtos.DisasterStatus activate(UUID actorId, DisasterDtos.ActivateDisasterRequest request) {
        this.active = true;
        this.disasterType = request.disasterType();
        this.disasterLevel = request.disasterLevel();
        this.affectedArea = request.affectedArea();
        this.activatedAt = Instant.now();

        audit.record(actorId, "DISASTER_MODE_ACTIVATED", "DISASTER", null,
            Map.of("type", disasterType, "level", disasterLevel, "area", affectedArea));

        notifications.broadcast(
            NotificationType.SYSTEM,
            "🚨 DISASTER MODE ACTIVATED: " + disasterType,
            "Disaster response level " + disasterLevel + " initiated for " + affectedArea + ". Responders follow START triage protocols."
        );

        return getStatus();
    }

    @Transactional
    public DisasterDtos.DisasterStatus deactivate(UUID actorId) {
        this.active = false;
        audit.record(actorId, "DISASTER_MODE_DEACTIVATED", "DISASTER", null, Map.of());
        notifications.broadcast(
            NotificationType.SYSTEM,
            "Disaster Mode Deactivated",
            "Operations returned to standard emergency response protocol."
        );
        return getStatus();
    }

    public DisasterDtos.DisasterOverview getOverview() {
        List<Incident> activeIncidents = incidents.findByStatusInOrderByCreatedAtDesc(
            List.of(
                com.smartaid.platform.incident.IncidentStatus.NEW,
                com.smartaid.platform.incident.IncidentStatus.SEARCHING,
                com.smartaid.platform.incident.IncidentStatus.RESPONDER_ASSIGNED,
                com.smartaid.platform.incident.IncidentStatus.EMS_ASSIGNED,
                com.smartaid.platform.incident.IncidentStatus.IN_TRANSIT
            )
        );

        int red = 0, yellow = 0, green = 0, black = 0;
        List<DisasterDtos.MassCasualtyIncident> list = new ArrayList<>();

        for (Incident inc : activeIncidents) {
            UUID incId = inc.getId() != null ? inc.getId() : UUID.randomUUID();
            String tag = triageTags.computeIfAbsent(incId, id -> inferDefaultTag(inc));
            switch (tag) {
                case "RED" -> red++;
                case "YELLOW" -> yellow++;
                case "GREEN" -> green++;
                case "BLACK" -> black++;
            }
            list.add(new DisasterDtos.MassCasualtyIncident(
                inc.getId(),
                inc.getEmergencyType().getLabel(),
                inc.getStatus().name(),
                inc.getPriority(),
                tag,
                inc.getLatitude(),
                inc.getLongitude(),
                inc.getNotes(),
                inc.getCreatedAt(),
                inc.getStatus().name().contains("ASSIGNED") ? 2 : 0
            ));
        }

        // Sort by priority: RED first, then YELLOW, then GREEN, then BLACK
        list.sort((a, b) -> Integer.compare(tagRank(a.triageTag()), tagRank(b.triageTag())));

        return new DisasterDtos.DisasterOverview(getStatus(), list, red, yellow, green, black);
    }

    public void updateTriageTag(UUID actorId, UUID incidentId, String tag, String notes) {
        triageTags.put(incidentId, tag);
        audit.record(actorId, "TRIAGE_TAG_UPDATED", "INCIDENT", incidentId,
            Map.of("tag", tag, "notes", notes != null ? notes : ""));
    }

    private int tagRank(String tag) {
        return switch (tag) {
            case "RED" -> 1;
            case "YELLOW" -> 2;
            case "GREEN" -> 3;
            case "BLACK" -> 4;
            default -> 5;
        };
    }

    private String inferDefaultTag(Incident inc) {
        String p = inc.getPriority();
        if ("CRITICAL".equalsIgnoreCase(p)) return "RED";
        if ("HIGH".equalsIgnoreCase(p)) return "YELLOW";
        return "GREEN";
    }
}
