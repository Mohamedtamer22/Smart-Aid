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
@Table(name = "medicines")
public class Medicine {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(name = "active_ingredient", length = 160)
    private String activeIngredient;

    @Column(name = "dosage_form", length = 64)
    private String dosageForm;

    @Column(name = "is_emergency_supply", nullable = false)
    private boolean isEmergencySupply;

    @Column(name = "prescription_required", nullable = false)
    private boolean prescriptionRequired;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public Medicine() { }

    public Medicine(String name, String activeIngredient, String dosageForm, boolean isEmergencySupply, boolean prescriptionRequired) {
        this.name = name;
        this.activeIngredient = activeIngredient;
        this.dosageForm = dosageForm;
        this.isEmergencySupply = isEmergencySupply;
        this.prescriptionRequired = prescriptionRequired;
        this.createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getActiveIngredient() { return activeIngredient; }
    public String getDosageForm() { return dosageForm; }
    public boolean isEmergencySupply() { return isEmergencySupply; }
    public boolean isPrescriptionRequired() { return prescriptionRequired; }
    public Instant getCreatedAt() { return createdAt; }
}
