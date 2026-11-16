package com.smartaid.platform.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "emergency_contacts")
public class EmergencyContact {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(name = "user_id", nullable = false) private UUID userId;
    @Column(name = "full_name", nullable = false) private String fullName;
    private String relationship;
    @Column(nullable = false) private String phone;
    @Column(name = "is_primary", nullable = false) private boolean primary;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    protected EmergencyContact() { }
    public EmergencyContact(UUID userId, String fullName, String relationship, String phone, boolean primary) {
        this.userId = userId; update(fullName, relationship, phone, primary);
    }
    @PrePersist void created() { createdAt = Instant.now(); }
    public void update(String fullName, String relationship, String phone, boolean primary) {
        this.fullName = fullName.trim(); this.relationship = relationship == null || relationship.isBlank() ? null : relationship.trim(); this.phone = phone.trim(); this.primary = primary;
    }
    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public String getFullName() { return fullName; }
    public String getRelationship() { return relationship; }
    public String getPhone() { return phone; }
    public boolean isPrimary() { return primary; }
}
