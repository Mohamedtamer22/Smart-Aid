package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MedicineRepository extends JpaRepository<Medicine, UUID> {
    List<Medicine> findByNameContainingIgnoreCaseOrActiveIngredientContainingIgnoreCase(String name, String activeIngredient);
    List<Medicine> findByIsEmergencySupplyTrueOrderByNameAsc();
}
