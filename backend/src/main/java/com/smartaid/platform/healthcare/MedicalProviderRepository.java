package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MedicalProviderRepository extends JpaRepository<MedicalProvider, UUID> {
    List<MedicalProvider> findByVerifiedTrueOrderByNameAsc();
    List<MedicalProvider> findByVerifiedTrueAndProviderTypeIgnoreCaseOrderByNameAsc(String providerType);
}
