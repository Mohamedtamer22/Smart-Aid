package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LabServiceRepository extends JpaRepository<LabServiceEntity, UUID> {
    List<LabServiceEntity> findByLaboratoryIdOrderByServiceNameAsc(UUID laboratoryId);
}
