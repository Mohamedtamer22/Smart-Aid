package com.smartaid.platform.training;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingLessonRepository extends JpaRepository<TrainingLesson, UUID> {
    List<TrainingLesson> findByCourseIdOrderBySortOrderAsc(UUID courseId);
}
