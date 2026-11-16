package com.smartaid.platform.profile;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface EmergencyContactRepository extends JpaRepository<EmergencyContact, UUID> {
    List<EmergencyContact> findByUserIdOrderByPrimaryDescCreatedAtAsc(UUID userId);
    Optional<EmergencyContact> findByIdAndUserId(UUID id, UUID userId);
}
