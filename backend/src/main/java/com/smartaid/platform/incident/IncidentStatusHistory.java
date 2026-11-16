package com.smartaid.platform.incident;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "incident_status_history")
public class IncidentStatusHistory {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(name = "incident_id") private UUID incidentId;
    @Column(name = "from_status") private String fromStatus;
    @Column(name = "to_status") private String toStatus;
    @Column(name = "actor_id") private UUID actorId;
    private String reason;
    @Column(name = "created_at") private Instant createdAt;
    protected IncidentStatusHistory() { }
    public IncidentStatusHistory(UUID incidentId, IncidentStatus from, IncidentStatus to, UUID actorId, String reason) {
        this.incidentId = incidentId; this.fromStatus = from == null ? null : from.name(); this.toStatus = to.name(); this.actorId = actorId; this.reason = reason; this.createdAt = Instant.now();
    }
    public IncidentStatus getFromStatus() { return fromStatus == null ? null : IncidentStatus.valueOf(fromStatus); }
    public IncidentStatus getToStatus() { return IncidentStatus.valueOf(toStatus); }
    public String getReason() { return reason; }
    public Instant getCreatedAt() { return createdAt; }
}
