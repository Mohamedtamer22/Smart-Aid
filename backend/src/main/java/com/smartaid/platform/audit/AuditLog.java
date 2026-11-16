package com.smartaid.platform.audit;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
public class AuditLog {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(name = "actor_id") private UUID actorId;
    private String action;
    @Column(name = "entity_type") private String entityType;
    @Column(name = "entity_id") private UUID entityId;
    @Column(name = "trace_id") private String traceId;
    @Column(name = "created_at") private Instant createdAt;
    protected AuditLog() { }
    AuditLog(UUID actorId, String action, String entityType, UUID entityId, String traceId) { this.actorId = actorId; this.action = action; this.entityType = entityType; this.entityId = entityId; this.traceId = traceId; this.createdAt = Instant.now(); }
    public UUID getId() { return id; }
    public UUID getActorId() { return actorId; }
    public String getAction() { return action; }
    public String getEntityType() { return entityType; }
    public UUID getEntityId() { return entityId; }
    public String getTraceId() { return traceId; }
    public Instant getCreatedAt() { return createdAt; }
}
