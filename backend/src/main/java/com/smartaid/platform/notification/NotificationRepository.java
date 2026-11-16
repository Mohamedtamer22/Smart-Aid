package com.smartaid.platform.notification;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface NotificationRepository extends JpaRepository<NotificationRecord, UUID> {
    List<NotificationRecord> findTop100ByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<NotificationRecord> findByIdAndUserId(UUID id, UUID userId);
}
