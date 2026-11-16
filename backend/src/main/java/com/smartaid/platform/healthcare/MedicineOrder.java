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
@Table(name = "medicine_orders")
public class MedicineOrder {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "pharmacy_id", nullable = false)
    private UUID pharmacyId;

    @Column(name = "medicine_id", nullable = false)
    private UUID medicineId;

    @Column(nullable = false)
    private int quantity = 1;

    @Column(name = "order_status", nullable = false, length = 32)
    private String orderStatus = "PLACED";

    @Column(name = "delivery_requested", nullable = false)
    private boolean deliveryRequested;

    @Column(name = "delivery_address")
    private String deliveryAddress;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public MedicineOrder() { }

    public MedicineOrder(UUID userId, UUID pharmacyId, UUID medicineId, int quantity, boolean deliveryRequested, String deliveryAddress) {
        this.userId = userId;
        this.pharmacyId = pharmacyId;
        this.medicineId = medicineId;
        this.quantity = Math.max(1, quantity);
        this.orderStatus = "PLACED";
        this.deliveryRequested = deliveryRequested;
        this.deliveryAddress = deliveryAddress;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public UUID getPharmacyId() { return pharmacyId; }
    public UUID getMedicineId() { return medicineId; }
    public int getQuantity() { return quantity; }
    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; this.updatedAt = Instant.now(); }
    public boolean isDeliveryRequested() { return deliveryRequested; }
    public String getDeliveryAddress() { return deliveryAddress; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
