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
@Table(name = "medical_handovers")
public class MedicalHandover {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "incident_id", nullable = false)
    private UUID incidentId;

    @Column(name = "ems_responder_id", nullable = false)
    private UUID emsResponderId;

    @Column(name = "receiving_hospital_id", nullable = false)
    private UUID receivingHospitalId;

    @Column(name = "receiving_staff_name", length = 120)
    private String receivingStaffName;

    @Column(name = "triage_summary")
    private String triageSummary;

    @Column(name = "vital_signs")
    private String vitalSigns;

    @Column(name = "interventions_administered")
    private String interventionsAdministered;

    @Column(name = "allergy_alerts")
    private String allergyAlerts;

    @Column(name = "medication_notes")
    private String medicationNotes;

    @Column(name = "handover_status", nullable = false, length = 32)
    private String handoverStatus = "TRANSFERRED";

    @Column(name = "transferred_at", nullable = false)
    private Instant transferredAt = Instant.now();

    @Column(name = "acknowledged_at")
    private Instant acknowledgedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public MedicalHandover() { }

    public MedicalHandover(UUID incidentId, UUID emsResponderId, UUID receivingHospitalId, String triageSummary,
                           String vitalSigns, String interventionsAdministered, String allergyAlerts, String medicationNotes) {
        this.incidentId = incidentId;
        this.emsResponderId = emsResponderId;
        this.receivingHospitalId = receivingHospitalId;
        this.triageSummary = triageSummary;
        this.vitalSigns = vitalSigns;
        this.interventionsAdministered = interventionsAdministered;
        this.allergyAlerts = allergyAlerts;
        this.medicationNotes = medicationNotes;
        this.handoverStatus = "TRANSFERRED";
        this.transferredAt = Instant.now();
        this.createdAt = Instant.now();
    }

    public void acknowledge(String staffName) {
        this.receivingStaffName = staffName;
        this.handoverStatus = "ACKNOWLEDGED";
        this.acknowledgedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getIncidentId() { return incidentId; }
    public UUID getEmsResponderId() { return emsResponderId; }
    public UUID getReceivingHospitalId() { return receivingHospitalId; }
    public String getReceivingStaffName() { return receivingStaffName; }
    public String getTriageSummary() { return triageSummary; }
    public String getVitalSigns() { return vitalSigns; }
    public String getInterventionsAdministered() { return interventionsAdministered; }
    public String getAllergyAlerts() { return allergyAlerts; }
    public String getMedicationNotes() { return medicationNotes; }
    public String getHandoverStatus() { return handoverStatus; }
    public Instant getTransferredAt() { return transferredAt; }
    public Instant getAcknowledgedAt() { return acknowledgedAt; }
    public Instant getCreatedAt() { return createdAt; }
}
