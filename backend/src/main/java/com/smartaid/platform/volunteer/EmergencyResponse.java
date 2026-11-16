package com.smartaid.platform.volunteer;

import com.smartaid.platform.exception.ApiException;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;

@Entity
@Table(name = "emergency_responses")
public class EmergencyResponse {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "incident_id", nullable = false)
    private UUID incidentId;

    @Column(name = "volunteer_id", nullable = false)
    private UUID volunteerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "response_status", nullable = false)
    private MissionStatus responseStatus;

    @Column(name = "task_type", length = 64)
    private String taskType;

    @Column(name = "task_notes")
    private String taskNotes;

    @Column(name = "eta_minutes")
    private Integer etaMinutes;

    @Column(name = "accepted_at")
    private Instant acceptedAt;

    @Column(name = "arrived_at")
    private Instant arrivedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected EmergencyResponse() { }

    public EmergencyResponse(UUID incidentId, UUID volunteerId, int etaMinutes) {
        this(incidentId, volunteerId, etaMinutes, "PRIMARY_RESPONSE", null);
    }

    public EmergencyResponse(UUID incidentId, UUID volunteerId, int etaMinutes, String taskType, String taskNotes) {
        this.incidentId = incidentId;
        this.volunteerId = volunteerId;
        this.etaMinutes = etaMinutes;
        this.taskType = taskType != null ? taskType : "PRIMARY_RESPONSE";
        this.taskNotes = taskNotes;
        this.responseStatus = MissionStatus.ACCEPTED;
        this.acceptedAt = Instant.now();
    }

    @PrePersist
    void created() {
        createdAt = Instant.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void updated() {
        updatedAt = Instant.now();
    }

    public void moveTo(MissionStatus next) {
        if (!responseStatus.allowedNext().contains(next)) {
            throw new ApiException(HttpStatus.CONFLICT, "INVALID_MISSION_TRANSITION", "This mission status transition is not allowed");
        }
        responseStatus = next;
        if (next == MissionStatus.ARRIVED) {
            arrivedAt = Instant.now();
        }
        if (next == MissionStatus.COMPLETED) {
            completedAt = Instant.now();
        }
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getIncidentId() { return incidentId; }
    public UUID getVolunteerId() { return volunteerId; }
    public MissionStatus getResponseStatus() { return responseStatus; }
    public String getTaskType() { return taskType; }
    public void setTaskType(String taskType) { this.taskType = taskType; }
    public String getTaskNotes() { return taskNotes; }
    public void setTaskNotes(String taskNotes) { this.taskNotes = taskNotes; }
    public Integer getEtaMinutes() { return etaMinutes; }
    public Instant getAcceptedAt() { return acceptedAt; }
    public Instant getArrivedAt() { return arrivedAt; }
    public Instant getCompletedAt() { return completedAt; }
}
