package com.smartaid.platform.healthcare;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "blood_requests")
public class BloodRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "requester_id", nullable = false)
    private UUID requesterId;

    @Column(name = "blood_bank_id")
    private UUID bloodBankId;

    @Column(name = "incident_id")
    private UUID incidentId;

    @Column(name = "blood_group", nullable = false, length = 8)
    private String bloodGroup;

    @Column(name = "units_requested", nullable = false)
    private int unitsRequested = 1;

    @Column(nullable = false, length = 32)
    private String urgency = "STANDARD";

    @Column(nullable = false, length = 32)
    private String status = "PENDING";

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public BloodRequest() { }

    public BloodRequest(UUID requesterId, UUID bloodBankId, UUID incidentId, String bloodGroup, int unitsRequested, String urgency) {
        this.requesterId = requesterId;
        this.bloodBankId = bloodBankId;
        this.incidentId = incidentId;
        this.bloodGroup = bloodGroup.toUpperCase();
        this.unitsRequested = Math.max(1, unitsRequested);
        this.urgency = urgency != null ? urgency.toUpperCase() : "STANDARD";
        this.status = "PENDING";
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getRequesterId() { return requesterId; }
    public UUID getBloodBankId() { return bloodBankId; }
    public UUID getIncidentId() { return incidentId; }
    public String getBloodGroup() { return bloodGroup; }
    public int getUnitsRequested() { return unitsRequested; }
    public String getUrgency() { return urgency; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; this.updatedAt = Instant.now(); }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
