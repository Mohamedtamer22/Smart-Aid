package com.smartaid.platform.triage;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface TriageAssessmentRepository extends JpaRepository<TriageAssessment, UUID> { }
