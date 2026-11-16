package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MedicineOrderRepository extends JpaRepository<MedicineOrder, UUID> {
    List<MedicineOrder> findByUserIdOrderByCreatedAtDesc(UUID userId);
    List<MedicineOrder> findByOrderStatusOrderByCreatedAtDesc(String orderStatus);
    List<MedicineOrder> findByPharmacyIdOrderByCreatedAtDesc(UUID pharmacyId);
}
