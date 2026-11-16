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
@Table(name = "lab_appointments")
public class LabAppointment {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "laboratory_id", nullable = false)
    private UUID laboratoryId;

    @Column(name = "lab_service_id", nullable = false)
    private UUID labServiceId;

    @Column(name = "scheduled_at", nullable = false)
    private Instant scheduledAt;

    @Column(nullable = false, length = 32)
    private String status = "BOOKED";

    @Column(name = "result_summary")
    private String resultSummary;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public LabAppointment() { }

    public LabAppointment(UUID userId, UUID laboratoryId, UUID labServiceId, Instant scheduledAt) {
        this.userId = userId;
        this.laboratoryId = laboratoryId;
        this.labServiceId = labServiceId;
        this.scheduledAt = scheduledAt != null ? scheduledAt : Instant.now().plusSeconds(3600);
        this.status = "BOOKED";
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public UUID getLaboratoryId() { return laboratoryId; }
    public UUID getLabServiceId() { return labServiceId; }
    public Instant getScheduledAt() { return scheduledAt; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; this.updatedAt = Instant.now(); }
    public String getResultSummary() { return resultSummary; }
    public void setResultSummary(String resultSummary) { this.resultSummary = resultSummary; this.updatedAt = Instant.now(); }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
