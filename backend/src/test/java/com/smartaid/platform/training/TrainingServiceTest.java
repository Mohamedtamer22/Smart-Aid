package com.smartaid.platform.training;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

class TrainingServiceTest {
    private TrainingCourseRepository courses;
    private TrainingLessonRepository lessons;
    private TrainingResultRepository results;
    private JdbcTemplate jdbc;
    private TrainingService service;

    @BeforeEach
    void setUp() {
        courses = mock(TrainingCourseRepository.class);
        lessons = mock(TrainingLessonRepository.class);
        results = mock(TrainingResultRepository.class);
        jdbc = mock(JdbcTemplate.class);
        service = new TrainingService(courses, lessons, results, jdbc);
    }

    @Test
    void submitQuiz_awards_certification_when_passing_threshold_met() {
        UUID userId = UUID.randomUUID();
        UUID courseId = UUID.randomUUID();
        TrainingCourse course = new TrainingCourse("Adult CPR & Automated External Defibrillator (AED)", "CPR description", false);

        when(courses.findById(courseId)).thenReturn(Optional.of(course));
        when(results.findByUserIdAndCourseId(userId, courseId)).thenReturn(Optional.empty());
        when(jdbc.query(anyString(), any(RowMapper.class), eq("CPR_AED"))).thenReturn(List.of((short) 101));

        // Submit all correct answers: 1, 0, 2
        TrainingDtos.QuizResult result = service.submitQuiz(userId, courseId, List.of(1, 0, 2));

        assertTrue(result.passed());
        assertEquals(new BigDecimal("100.00"), result.score());
        assertEquals("CPR_AED", result.certificationCode());
        assertNotNull(result.feedback());
        assertTrue(result.feedback().contains("passed"));
    }

    @Test
    void submitQuiz_rejects_certification_when_score_below_80_percent() {
        UUID userId = UUID.randomUUID();
        UUID courseId = UUID.randomUUID();
        TrainingCourse course = new TrainingCourse("Adult CPR & Automated External Defibrillator (AED)", "CPR description", false);

        when(courses.findById(courseId)).thenReturn(Optional.of(course));
        when(results.findByUserIdAndCourseId(userId, courseId)).thenReturn(Optional.empty());

        // Submit wrong answers
        TrainingDtos.QuizResult result = service.submitQuiz(userId, courseId, List.of(0, 2, 1));

        assertFalse(result.passed());
        assertTrue(result.score().compareTo(BigDecimal.valueOf(80.0)) < 0);
        assertNull(result.certificationCode());
        assertTrue(result.feedback().contains("80% or higher"));
    }
}
