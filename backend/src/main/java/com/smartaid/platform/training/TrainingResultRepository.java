package com.smartaid.platform.training;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingResultRepository extends JpaRepository<TrainingResult, UUID> {
    Optional<TrainingResult> findByUserIdAndCourseId(UUID userId, UUID courseId);
    List<TrainingResult> findByUserId(UUID userId);
}
