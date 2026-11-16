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
@Table(name = "medical_providers")
public class MedicalProvider {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(name = "provider_type", nullable = false, length = 64)
    private String providerType;

    @Column(length = 120)
    private String specialty;

    @Column(nullable = false)
    private String address;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(length = 32)
    private String phone;

    @Column(nullable = false)
    private boolean verified = true;

    @Column(name = "telemedicine_enabled", nullable = false)
    private boolean telemedicineEnabled;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public MedicalProvider() { }

    public MedicalProvider(String name, String providerType, String specialty, String address, double latitude, double longitude, String phone, boolean verified, boolean telemedicineEnabled) {
        this.name = name;
        this.providerType = providerType.toUpperCase();
        this.specialty = specialty;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
        this.phone = phone;
        this.verified = verified;
        this.telemedicineEnabled = telemedicineEnabled;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getProviderType() { return providerType; }
    public String getSpecialty() { return specialty; }
    public String getAddress() { return address; }
    public double getLatitude() { return latitude; }
    public double getLongitude() { return longitude; }
    public String getPhone() { return phone; }
    public boolean isVerified() { return verified; }
    public boolean isTelemedicineEnabled() { return telemedicineEnabled; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
