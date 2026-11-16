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
@Table(name = "ambulances")
public class Ambulance {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "call_sign", nullable = false, unique = true, length = 50)
    private String callSign;

    @Column(nullable = false, length = 20)
    private String status;

    private Double latitude;
    private Double longitude;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Ambulance() {
        this.updatedAt = Instant.now();
        this.status = "AVAILABLE";
    }

    public Ambulance(String callSign, String status, Double latitude, Double longitude) {
        this.callSign = callSign;
        this.status = status != null ? status : "AVAILABLE";
        this.latitude = latitude;
        this.longitude = longitude;
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public String getCallSign() { return callSign; }
    public void setCallSign(String callSign) { this.callSign = callSign; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
