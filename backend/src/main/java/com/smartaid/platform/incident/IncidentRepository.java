package com.smartaid.platform.incident;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
public interface IncidentRepository extends JpaRepository<Incident, UUID> {
    List<Incident> findByReporterIdOrderByCreatedAtDesc(UUID reporterId);
    List<Incident> findByStatusOrderByCreatedAtDesc(IncidentStatus status);
    List<Incident> findByStatusInOrderByCreatedAtDesc(java.util.Collection<IncidentStatus> statuses);
    long countByStatusIn(java.util.Collection<IncidentStatus> statuses);
    List<Incident> findAllByOrderByCreatedAtDesc();
    boolean existsByNotes(String notes);
    boolean existsByIdAndReporterId(UUID id, UUID reporterId);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select incident from Incident incident where incident.id = :id")
    java.util.Optional<Incident> findByIdForUpdate(@Param("id") UUID id);
}
