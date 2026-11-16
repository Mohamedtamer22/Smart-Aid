package com.smartaid.platform.volunteer;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;

public interface VolunteerSkillRepository extends Repository<VolunteerProfile, UUID> {
    @Query(value = "select s.code from skills s join volunteer_skills vs on vs.skill_id = s.id where vs.volunteer_id = :volunteerId", nativeQuery = true)
    List<String> findSkillCodes(UUID volunteerId);
}
