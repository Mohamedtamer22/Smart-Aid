package com.smartaid.platform.training;

import jakarta.validation.constraints.NotEmpty;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public class TrainingDtos {
    public record CourseSummary(
        UUID id,
        String title,
        String description,
        boolean mockContent,
        int lessonCount,
        BigDecimal userScore,
        boolean passed,
        String certificationCode,
        java.time.Instant completedAt
    ) {
        public CourseSummary(UUID id, String title, String description, boolean mockContent, int lessonCount, BigDecimal userScore, boolean passed) {
            this(id, title, description, mockContent, lessonCount, userScore, passed, null, null);
        }
    }

    public record LessonDto(
        UUID id,
        UUID courseId,
        String title,
        String content,
        short sortOrder
    ) {}

    public record QuizQuestion(
        int id,
        String question,
        List<String> options
    ) {}

    public record CourseDetail(
        UUID id,
        String title,
        String description,
        List<LessonDto> lessons,
        List<QuizQuestion> quiz
    ) {}

    public record SubmitQuizRequest(
        @NotEmpty List<Integer> answers
    ) {}

    public record QuizResult(
        BigDecimal score,
        boolean passed,
        String feedback,
        String certificationCode
    ) {}
}
