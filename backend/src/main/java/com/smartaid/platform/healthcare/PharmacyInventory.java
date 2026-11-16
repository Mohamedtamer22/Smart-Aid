package com.smartaid.platform.healthcare;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "pharmacy_inventory")
public class PharmacyInventory {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "pharmacy_id", nullable = false)
    private UUID pharmacyId;

    @Column(name = "medicine_id", nullable = false)
    private UUID medicineId;

    @Column(name = "stock_quantity", nullable = false)
    private int stockQuantity;

    @Column(name = "unit_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal unitPrice = BigDecimal.ZERO;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public PharmacyInventory() { }

    public PharmacyInventory(UUID pharmacyId, UUID medicineId, int stockQuantity, BigDecimal unitPrice) {
        this.pharmacyId = pharmacyId;
        this.medicineId = medicineId;
        this.stockQuantity = Math.max(0, stockQuantity);
        this.unitPrice = unitPrice != null ? unitPrice : BigDecimal.ZERO;
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getPharmacyId() { return pharmacyId; }
    public UUID getMedicineId() { return medicineId; }
    public int getStockQuantity() { return stockQuantity; }
    public void setStockQuantity(int stockQuantity) { this.stockQuantity = Math.max(0, stockQuantity); this.updatedAt = Instant.now(); }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice != null ? unitPrice : BigDecimal.ZERO; this.updatedAt = Instant.now(); }
    public Instant getUpdatedAt() { return updatedAt; }
}
