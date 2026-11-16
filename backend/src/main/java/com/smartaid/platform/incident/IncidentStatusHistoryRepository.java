package com.smartaid.platform.incident;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface IncidentStatusHistoryRepository extends JpaRepository<IncidentStatusHistory, UUID> {
    java.util.List<IncidentStatusHistory> findByIncidentIdOrderByCreatedAtAsc(UUID incidentId);
}
