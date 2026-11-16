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
@Table(name = "pharmacies")
public class Pharmacy {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(nullable = false)
    private String address;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(length = 32)
    private String phone;

    @Column(name = "opening_hours", nullable = false, length = 120)
    private String openingHours;

    @Column(nullable = false)
    private boolean verified;

    @Column(name = "emergency_supplies_available", nullable = false)
    private boolean emergencySuppliesAvailable;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public Pharmacy() { }

    public Pharmacy(String name, String address, double latitude, double longitude, String phone, String openingHours, boolean verified, boolean emergencySuppliesAvailable) {
        this.name = name;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
        this.phone = phone;
        this.openingHours = openingHours != null ? openingHours : "24/7";
        this.verified = verified;
        this.emergencySuppliesAvailable = emergencySuppliesAvailable;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getAddress() { return address; }
    public double getLatitude() { return latitude; }
    public double getLongitude() { return longitude; }
    public String getPhone() { return phone; }
    public String getOpeningHours() { return openingHours; }
    public boolean isVerified() { return verified; }
    public boolean isEmergencySuppliesAvailable() { return emergencySuppliesAvailable; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
