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
@Table(name = "provider_appointments")
public class ProviderAppointment {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "provider_id", nullable = false)
    private UUID providerId;

    @Column(name = "scheduled_at", nullable = false)
    private Instant scheduledAt;

    @Column(name = "appointment_type", nullable = false, length = 32)
    private String appointmentType = "IN_PERSON";

    @Column(nullable = false, length = 32)
    private String status = "SCHEDULED";

    @Column(name = "chief_complaint")
    private String chiefComplaint;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public ProviderAppointment() { }

    public ProviderAppointment(UUID userId, UUID providerId, Instant scheduledAt, String appointmentType, String chiefComplaint) {
        this.userId = userId;
        this.providerId = providerId;
        this.scheduledAt = scheduledAt != null ? scheduledAt : Instant.now().plusSeconds(3600);
        this.appointmentType = appointmentType != null ? appointmentType.toUpperCase() : "IN_PERSON";
        this.status = "SCHEDULED";
        this.chiefComplaint = chiefComplaint;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public UUID getProviderId() { return providerId; }
    public Instant getScheduledAt() { return scheduledAt; }
    public String getAppointmentType() { return appointmentType; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; this.updatedAt = Instant.now(); }
    public String getChiefComplaint() { return chiefComplaint; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
