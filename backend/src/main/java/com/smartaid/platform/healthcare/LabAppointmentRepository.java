package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LabAppointmentRepository extends JpaRepository<LabAppointment, UUID> {
    List<LabAppointment> findByUserIdOrderByCreatedAtDesc(UUID userId);
    List<LabAppointment> findByLaboratoryIdOrderByScheduledAtAsc(UUID laboratoryId);
}
