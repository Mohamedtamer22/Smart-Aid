package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BloodInventoryRepository extends JpaRepository<BloodInventory, UUID> {
    List<BloodInventory> findByBloodBankIdOrderByBloodGroupAsc(UUID bloodBankId);
    Optional<BloodInventory> findByBloodBankIdAndBloodGroupIgnoreCase(UUID bloodBankId, String bloodGroup);
    List<BloodInventory> findByBloodGroupIgnoreCaseAndUnitsAvailableGreaterThan(String bloodGroup, int minUnits);
}
