package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PharmacyRepository extends JpaRepository<Pharmacy, UUID> {
    List<Pharmacy> findByVerifiedTrueOrderByNameAsc();
    List<Pharmacy> findByVerifiedTrueAndEmergencySuppliesAvailableTrueOrderByNameAsc();
}
