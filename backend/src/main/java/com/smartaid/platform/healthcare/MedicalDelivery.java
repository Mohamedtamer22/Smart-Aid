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
@Table(name = "medical_deliveries")
public class MedicalDelivery {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "tracking_code", nullable = false, unique = true, length = 64)
    private String trackingCode;

    @Column(name = "courier_name", length = 120)
    private String courierName;

    @Column(name = "courier_phone", length = 32)
    private String courierPhone;

    @Column(name = "delivery_status", nullable = false, length = 32)
    private String deliveryStatus = "ASSIGNED";

    @Column(name = "eta_minutes")
    private Integer etaMinutes;

    @Column(name = "pickup_address")
    private String pickupAddress;

    @Column(name = "delivery_address")
    private String deliveryAddress;

    @Column(name = "delivered_at")
    private Instant deliveredAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public MedicalDelivery() { }

    public MedicalDelivery(UUID orderId, String trackingCode, String courierName, String courierPhone, Integer etaMinutes, String pickupAddress, String deliveryAddress) {
        this.orderId = orderId;
        this.trackingCode = trackingCode;
        this.courierName = courierName;
        this.courierPhone = courierPhone;
        this.deliveryStatus = "ASSIGNED";
        this.etaMinutes = etaMinutes != null ? etaMinutes : 25;
        this.pickupAddress = pickupAddress;
        this.deliveryAddress = deliveryAddress;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getOrderId() { return orderId; }
    public String getTrackingCode() { return trackingCode; }
    public String getCourierName() { return courierName; }
    public String getCourierPhone() { return courierPhone; }
    public String getDeliveryStatus() { return deliveryStatus; }
    public void setDeliveryStatus(String deliveryStatus) {
        this.deliveryStatus = deliveryStatus;
        this.updatedAt = Instant.now();
        if ("DELIVERED".equalsIgnoreCase(deliveryStatus)) {
            this.deliveredAt = Instant.now();
            this.etaMinutes = 0;
        }
    }
    public Integer getEtaMinutes() { return etaMinutes; }
    public void setEtaMinutes(Integer etaMinutes) { this.etaMinutes = etaMinutes; this.updatedAt = Instant.now(); }
    public String getPickupAddress() { return pickupAddress; }
    public String getDeliveryAddress() { return deliveryAddress; }
    public Instant getDeliveredAt() { return deliveredAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
