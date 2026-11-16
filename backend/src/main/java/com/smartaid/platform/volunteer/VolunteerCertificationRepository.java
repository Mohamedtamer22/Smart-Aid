package com.smartaid.platform.volunteer;

import java.time.Instant;
import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;

public interface VolunteerCertificationRepository extends Repository<VolunteerProfile, UUID> {
    @Query(value = "select exists(select 1 from volunteer_certifications where volunteer_id = :volunteerId and verified_at is not null and expires_at > :now)", nativeQuery = true)
    boolean hasValidCertification(UUID volunteerId, Instant now);
}
