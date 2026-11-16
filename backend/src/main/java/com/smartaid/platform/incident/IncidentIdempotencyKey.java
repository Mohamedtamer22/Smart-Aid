package com.smartaid.platform.incident;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "incident_idempotency_keys", uniqueConstraints = @UniqueConstraint(name = "uq_incident_idempotency_key",
        columnNames = {"reporter_id", "request_key"}))
public class IncidentIdempotencyKey {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "reporter_id", nullable = false)
    private UUID reporterId;

    @Column(name = "request_key", nullable = false, length = 128)
    private String requestKey;

    @Column(name = "request_fingerprint", nullable = false, length = 64)
    private String requestFingerprint;

    @Column(name = "incident_id", nullable = false)
    private UUID incidentId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected IncidentIdempotencyKey() { }

    public IncidentIdempotencyKey(UUID reporterId, String requestKey, String requestFingerprint, UUID incidentId) {
        this.reporterId = reporterId;
        this.requestKey = requestKey;
        this.requestFingerprint = requestFingerprint;
        this.incidentId = incidentId;
    }

    @PrePersist
    void created() {
        createdAt = Instant.now();
    }

    public boolean matchesFingerprint(String fingerprint) {
        return requestFingerprint.equals(fingerprint);
    }

    public UUID getIncidentId() {
        return incidentId;
    }
}
