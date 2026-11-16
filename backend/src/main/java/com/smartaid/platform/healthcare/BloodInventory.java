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
@Table(name = "blood_inventory")
public class BloodInventory {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "blood_bank_id", nullable = false)
    private UUID bloodBankId;

    @Column(name = "blood_group", nullable = false, length = 8)
    private String bloodGroup;

    @Column(name = "units_available", nullable = false)
    private int unitsAvailable;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public BloodInventory() { }

    public BloodInventory(UUID bloodBankId, String bloodGroup, int unitsAvailable) {
        this.bloodBankId = bloodBankId;
        this.bloodGroup = bloodGroup.toUpperCase();
        this.unitsAvailable = Math.max(0, unitsAvailable);
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getBloodBankId() { return bloodBankId; }
    public String getBloodGroup() { return bloodGroup; }
    public int getUnitsAvailable() { return unitsAvailable; }
    public void setUnitsAvailable(int unitsAvailable) { this.unitsAvailable = Math.max(0, unitsAvailable); this.updatedAt = Instant.now(); }
    public Instant getUpdatedAt() { return updatedAt; }
}
