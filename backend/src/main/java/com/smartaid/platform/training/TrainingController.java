package com.smartaid.platform.training;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/training")
public class TrainingController {
    private final TrainingService trainingService;

    public TrainingController(TrainingService trainingService) {
        this.trainingService = trainingService;
    }

    @GetMapping("/courses")
    public List<TrainingDtos.CourseSummary> listCourses(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return trainingService.listCourses(userId);
    }

    @GetMapping("/courses/{id}")
    public TrainingDtos.CourseDetail getCourseDetail(@PathVariable UUID id) {
        return trainingService.getCourseDetail(id);
    }

    @PostMapping("/courses/{id}/quiz")
    public TrainingDtos.QuizResult submitQuiz(
        @PathVariable UUID id,
        @Valid @RequestBody TrainingDtos.SubmitQuizRequest request,
        Authentication authentication
    ) {
        UUID userId = (UUID) authentication.getPrincipal();
        return trainingService.submitQuiz(userId, id, request.answers());
    }
}
