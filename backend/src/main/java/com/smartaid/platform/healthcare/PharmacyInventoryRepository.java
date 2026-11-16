package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PharmacyInventoryRepository extends JpaRepository<PharmacyInventory, UUID> {
    List<PharmacyInventory> findByPharmacyId(UUID pharmacyId);
    Optional<PharmacyInventory> findByPharmacyIdAndMedicineId(UUID pharmacyId, UUID medicineId);
    List<PharmacyInventory> findByMedicineIdAndStockQuantityGreaterThan(UUID medicineId, int minStock);
}
