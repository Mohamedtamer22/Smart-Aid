package com.smartaid.platform.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "medical_profiles")
public class MedicalProfile {
    @Id @Column(name = "user_id") private UUID userId;
    @Column(name = "blood_type") private String bloodType;
    private String allergies;
    private String medications;
    @Column(name = "emergency_notes") private String emergencyNotes;
    @Column(name = "sharing_consent", nullable = false) private boolean sharingConsent;
    @Column(name = "updated_at", nullable = false) private Instant updatedAt;
    protected MedicalProfile() { }
    public MedicalProfile(UUID userId) { this.userId = userId; }
    @PrePersist @PreUpdate void timestamp() { updatedAt = Instant.now(); }
    public void update(String bloodType, String allergies, String medications, String emergencyNotes, boolean sharingConsent) {
        this.bloodType = blankToNull(bloodType); this.allergies = blankToNull(allergies); this.medications = blankToNull(medications);
        this.emergencyNotes = blankToNull(emergencyNotes); this.sharingConsent = sharingConsent;
    }
    private static String blankToNull(String value) { return value == null || value.isBlank() ? null : value.trim(); }
    public UUID getUserId() { return userId; }
    public String getBloodType() { return bloodType; }
    public String getAllergies() { return allergies; }
    public String getMedications() { return medications; }
    public String getEmergencyNotes() { return emergencyNotes; }
    public boolean isSharingConsent() { return sharingConsent; }
    public Instant getUpdatedAt() { return updatedAt; }
}
