package com.smartaid.platform.volunteer;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "volunteer_profiles")
public class VolunteerProfile {
    @Id @Column(name = "user_id") private UUID userId;
    private boolean verified;
    private boolean available;
    private Double latitude;
    private Double longitude;
    @Column(name = "updated_at") private Instant updatedAt;
    protected VolunteerProfile() { }
    public VolunteerProfile(UUID userId) { this.userId = userId; }
    @PrePersist @PreUpdate void updated() { updatedAt = Instant.now(); }
    public UUID getUserId() { return userId; }
    public boolean isVerified() { return verified; }
    public boolean isAvailable() { return available; }
    public Double getLatitude() { return latitude; }
    public Double getLongitude() { return longitude; }
    public void setAvailable(boolean value) { available = value; }
    public void setVerified(boolean value) { verified = value; }
    public void updateLocation(double newLatitude, double newLongitude) { latitude = newLatitude; longitude = newLongitude; }
    public Instant getUpdatedAt() { return updatedAt; }
}
