package com.smartaid.platform.resource;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "aed_devices")
public class AedDevice {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "resource_type", nullable = false)
    private String resourceType;

    @Column(nullable = false, length = 160)
    private String label;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(name = "availability_status", nullable = false, length = 32)
    private String availabilityStatus;

    @Column(nullable = false)
    private boolean verified;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public AedDevice() {
        this.updatedAt = Instant.now();
        this.resourceType = "AED";
        this.availabilityStatus = "AVAILABLE";
        this.verified = true;
    }

    public AedDevice(String label, double latitude, double longitude, String resourceType, String availabilityStatus, boolean verified) {
        this.label = label;
        this.latitude = latitude;
        this.longitude = longitude;
        this.resourceType = resourceType != null ? resourceType : "AED";
        this.availabilityStatus = availabilityStatus != null ? availabilityStatus : "AVAILABLE";
        this.verified = verified;
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public String getResourceType() { return resourceType; }
    public void setResourceType(String resourceType) { this.resourceType = resourceType; }
    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }
    public double getLatitude() { return latitude; }
    public void setLatitude(double latitude) { this.latitude = latitude; }
    public double getLongitude() { return longitude; }
    public void setLongitude(double longitude) { this.longitude = longitude; }
    public String getAvailabilityStatus() { return availabilityStatus; }
    public void setAvailabilityStatus(String availabilityStatus) { this.availabilityStatus = availabilityStatus; }
    public boolean isVerified() { return verified; }
    public void setVerified(boolean verified) { this.verified = verified; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
