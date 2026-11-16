package com.smartaid.platform.smarter;

import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;

public interface HospitalCapabilityRepository extends Repository<Hospital, UUID> {
    @Query(value = "select exists(select 1 from hospital_specialties where hospital_id = :hospitalId and specialty = :specialty and verified = true)", nativeQuery = true)
    boolean hasSpecialty(UUID hospitalId, String specialty);
    @Query(value = "select exists(select 1 from hospital_resources where hospital_id = :hospitalId and resource_code = :resourceCode and available = true and verified_at is not null)", nativeQuery = true)
    boolean hasAvailableResource(UUID hospitalId, String resourceCode);
}
