package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MedicalHandoverRepository extends JpaRepository<MedicalHandover, UUID> {
    Optional<MedicalHandover> findFirstByIncidentIdOrderByCreatedAtDesc(UUID incidentId);
    List<MedicalHandover> findByHandoverStatusOrderByCreatedAtDesc(String handoverStatus);
    List<MedicalHandover> findAllByOrderByCreatedAtDesc();
}
