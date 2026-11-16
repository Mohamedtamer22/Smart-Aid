package com.smartaid.platform.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * A registration request is intentionally separate from a verified hospital.
 * It never makes an unreviewed applicant eligible for Smart ER decisions.
 */
@Entity
@Table(name = "hospital_partner_requests")
public class HospitalPartnerRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "organization_name", nullable = false)
    private String organizationName;

    @Column(name = "registration_number")
    private String registrationNumber;

    @Column(nullable = false)
    private String status = "PENDING";

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected HospitalPartnerRequest() { }

    public HospitalPartnerRequest(UUID userId, String organizationName, String registrationNumber) {
        this.userId = userId;
        this.organizationName = organizationName;
        this.registrationNumber = registrationNumber;
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

    public UUID getUserId() { return userId; }
    public String getOrganizationName() { return organizationName; }
    public String getRegistrationNumber() { return registrationNumber; }
    public String getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
}
