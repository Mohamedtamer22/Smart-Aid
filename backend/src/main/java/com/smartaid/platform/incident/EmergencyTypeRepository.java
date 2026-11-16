package com.smartaid.platform.incident;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
public interface EmergencyTypeRepository extends JpaRepository<EmergencyType, Short> { Optional<EmergencyType> findByCode(String code); }
