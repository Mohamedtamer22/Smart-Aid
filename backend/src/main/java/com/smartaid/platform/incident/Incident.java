package com.smartaid.platform.incident;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "incidents")
public class Incident {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(name = "reporter_id", nullable = false) private UUID reporterId;
    @ManyToOne(fetch = FetchType.EAGER) @JoinColumn(name = "emergency_type_id", nullable = false) private EmergencyType emergencyType;
    @Column(nullable = false) private String source;
    @Enumerated(EnumType.STRING) @Column(nullable = false) private IncidentStatus status;
    @Column(nullable = false) private String priority;
    @Column(nullable = false) private double latitude;
    @Column(nullable = false) private double longitude;
    private String notes;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;
    protected Incident() { }
    public Incident(UUID reporterId, EmergencyType emergencyType, double latitude, double longitude, String notes, String priority) {
        this.reporterId = reporterId; this.emergencyType = emergencyType; this.latitude = latitude; this.longitude = longitude;
        this.notes = notes; this.priority = priority; this.source = "MANUAL"; this.status = IncidentStatus.NEW;
    }
    @PrePersist void created() { createdAt = Instant.now(); updatedAt = createdAt; }
    @PreUpdate void updated() { updatedAt = Instant.now(); }
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getReporterId() { return reporterId; }
    public EmergencyType getEmergencyType() { return emergencyType; }
    public String getSource() { return source; }
    public IncidentStatus getStatus() { return status; }
    public String getPriority() { return priority; }
    public double getLatitude() { return latitude; }
    public double getLongitude() { return longitude; }
    public String getNotes() { return notes; }
    public Instant getCreatedAt() { return createdAt; }
    public void moveTo(IncidentStatus status) { this.status = status; }
}
