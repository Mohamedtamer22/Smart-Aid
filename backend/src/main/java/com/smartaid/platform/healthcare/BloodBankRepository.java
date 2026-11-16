package com.smartaid.platform.healthcare;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BloodBankRepository extends JpaRepository<BloodBank, UUID> {
    List<BloodBank> findByVerifiedTrueOrderByNameAsc();
}
