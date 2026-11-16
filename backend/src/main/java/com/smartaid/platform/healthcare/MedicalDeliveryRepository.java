package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MedicalDeliveryRepository extends JpaRepository<MedicalDelivery, UUID> {
    Optional<MedicalDelivery> findByTrackingCodeIgnoreCase(String trackingCode);
    Optional<MedicalDelivery> findByOrderId(UUID orderId);
    List<MedicalDelivery> findAllByOrderByCreatedAtDesc();
}
