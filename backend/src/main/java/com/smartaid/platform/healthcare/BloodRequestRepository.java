package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BloodRequestRepository extends JpaRepository<BloodRequest, UUID> {
    List<BloodRequest> findAllByOrderByCreatedAtDesc();
    List<BloodRequest> findByRequesterIdOrderByCreatedAtDesc(UUID requesterId);
    List<BloodRequest> findByStatusOrderByCreatedAtDesc(String status);
}
