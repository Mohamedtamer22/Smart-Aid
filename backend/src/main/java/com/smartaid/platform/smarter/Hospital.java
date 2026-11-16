package com.smartaid.platform.smarter;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "hospitals")
public class Hospital {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    private String name;
    private double latitude;
    private double longitude;
    private boolean verified;
    @Column(name = "estimated_congestion") private Integer estimatedCongestion;
    @Column(name = "updated_at") private Instant updatedAt;
    public Hospital() { this.updatedAt = Instant.now(); }
    public Hospital(String name, double latitude, double longitude, boolean verified, Integer estimatedCongestion) {
        this.name = name;
        this.latitude = latitude;
        this.longitude = longitude;
        this.verified = verified;
        this.estimatedCongestion = estimatedCongestion;
        this.updatedAt = Instant.now();
    }
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public double getLatitude() { return latitude; }
    public void setLatitude(double latitude) { this.latitude = latitude; }
    public double getLongitude() { return longitude; }
    public void setLongitude(double longitude) { this.longitude = longitude; }
    public boolean isVerified() { return verified; }
    public void setVerified(boolean verified) { this.verified = verified; }
    public Integer getEstimatedCongestion() { return estimatedCongestion; }
    public void setEstimatedCongestion(Integer estimatedCongestion) { this.estimatedCongestion = estimatedCongestion; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
