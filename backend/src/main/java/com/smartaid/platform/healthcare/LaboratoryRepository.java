package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LaboratoryRepository extends JpaRepository<Laboratory, UUID> {
    List<Laboratory> findByVerifiedTrueOrderByNameAsc();
}
