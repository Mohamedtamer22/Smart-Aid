package com.smartaid.platform.profile;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface MedicalProfileRepository extends JpaRepository<MedicalProfile, UUID> { }
