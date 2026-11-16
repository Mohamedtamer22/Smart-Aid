package com.smartaid.platform.healthcare;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "lab_services")
public class LabServiceEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "laboratory_id", nullable = false)
    private UUID laboratoryId;

    @Column(name = "service_name", nullable = false, length = 160)
    private String serviceName;

    @Column(length = 64)
    private String category;

    @Column(name = "turnaround_hours")
    private Integer turnaroundHours = 24;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price = BigDecimal.ZERO;

    public LabServiceEntity() { }

    public LabServiceEntity(UUID laboratoryId, String serviceName, String category, Integer turnaroundHours, BigDecimal price) {
        this.laboratoryId = laboratoryId;
        this.serviceName = serviceName;
        this.category = category;
        this.turnaroundHours = turnaroundHours != null ? turnaroundHours : 24;
        this.price = price != null ? price : BigDecimal.ZERO;
    }

    public UUID getId() { return id; }
    public UUID getLaboratoryId() { return laboratoryId; }
    public String getServiceName() { return serviceName; }
    public String getCategory() { return category; }
    public Integer getTurnaroundHours() { return turnaroundHours; }
    public BigDecimal getPrice() { return price; }
}
