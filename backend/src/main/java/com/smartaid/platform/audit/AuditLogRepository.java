package com.smartaid.platform.audit;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {
    java.util.List<AuditLog> findTop50ByOrderByCreatedAtDesc();
}
