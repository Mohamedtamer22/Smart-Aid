package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProviderAppointmentRepository extends JpaRepository<ProviderAppointment, UUID> {
    List<ProviderAppointment> findByUserIdOrderByScheduledAtDesc(UUID userId);
    List<ProviderAppointment> findByProviderIdOrderByScheduledAtAsc(UUID providerId);
}
