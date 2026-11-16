package com.smartaid.platform.volunteer;

import java.util.Collection;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmergencyResponseRepository extends JpaRepository<EmergencyResponse, UUID> {
    Optional<EmergencyResponse> findByIncidentId(UUID incidentId);
    java.util.List<EmergencyResponse> findAllByIncidentId(UUID incidentId);
    Optional<EmergencyResponse> findFirstByVolunteerIdAndResponseStatusInOrderByCreatedAtDesc(UUID volunteerId, Collection<MissionStatus> statuses);
    boolean existsByIncidentIdAndVolunteerId(UUID incidentId, UUID volunteerId);
    long countByIncidentIdAndResponseStatusIn(UUID incidentId, Collection<MissionStatus> statuses);
}
