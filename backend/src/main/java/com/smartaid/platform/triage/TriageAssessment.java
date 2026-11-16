package com.smartaid.platform.triage;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "triage_assessments")
public class TriageAssessment {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(name = "incident_id") private UUID incidentId;
    private Boolean conscious;
    private Boolean breathing;
    @Column(name = "severe_bleeding") private Boolean severeBleeding;
    @Column(name = "chest_pain") private Boolean chestPain;
    @Column(name = "fall_occurred") private Boolean fallOccurred;
    @Column(name = "traffic_accident") private Boolean trafficAccident;
    private String summary;
    @Column(name = "rule_version") private String ruleVersion;
    @Column(name = "created_at") private Instant createdAt;
    protected TriageAssessment() { }
    public TriageAssessment(UUID incidentId, TriageInput input, String summary) {
        this.incidentId = incidentId; this.conscious = input.conscious(); this.breathing = input.breathing(); this.severeBleeding = input.severeBleeding(); this.chestPain = input.chestPain(); this.fallOccurred = input.fallOccurred(); this.trafficAccident = input.trafficAccident(); this.summary = summary; this.ruleVersion = "rules-v1"; this.createdAt = Instant.now();
    }
}
