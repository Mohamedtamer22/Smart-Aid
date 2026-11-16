package com.smartaid.platform.volunteer;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface VolunteerProfileRepository extends JpaRepository<VolunteerProfile, UUID> {
    List<VolunteerProfile> findByAvailableTrueAndVerifiedTrue();
    long countByVerifiedFalse();
    long countByVerifiedTrue();
}
