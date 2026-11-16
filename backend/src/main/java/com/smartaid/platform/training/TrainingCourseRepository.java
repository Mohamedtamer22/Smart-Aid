package com.smartaid.platform.training;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingCourseRepository extends JpaRepository<TrainingCourse, UUID> {
}
