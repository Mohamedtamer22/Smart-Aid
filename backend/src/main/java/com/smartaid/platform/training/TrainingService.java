package com.smartaid.platform.training;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TrainingService {
    private final TrainingCourseRepository courses;
    private final TrainingLessonRepository lessons;
    private final TrainingResultRepository results;
    private final JdbcTemplate jdbc;

    // Hardcoded authoritative quiz answer keys (0-indexed correct option)
    private static final Map<String, List<Integer>> ANSWER_KEYS = Map.of(
        "CPR_AED", List.of(1, 0, 2), // 1: 100-120 bpm, 0: Upper right & lower left, 2: 30:2
        "BLEEDING", List.of(0, 1, 0), // 0: Direct pressure, 1: 2-3 inches above wound, 0: Elevate and keep warm
        "TRIAGE", List.of(2, 0, 1)    // 2: Immediate (Red), 0: Check responsiveness & breathing, 1: Delayed (Yellow)
    );

    public TrainingService(TrainingCourseRepository courses, TrainingLessonRepository lessons,
                           TrainingResultRepository results, JdbcTemplate jdbc) {
        this.courses = courses;
        this.lessons = lessons;
        this.results = results;
        this.jdbc = jdbc;
    }

    @Transactional
    public void ensureDefaultCourses() {
        if (courses.count() > 0) return;

        TrainingCourse cpr = courses.save(new TrainingCourse(
            "Adult CPR & Automated External Defibrillator (AED)",
            "Learn essential lifesaving chest compressions, rescue breathing, and AED pad placement.",
            false
        ));
        lessons.save(new TrainingLesson(cpr.getId(), "Chest Compressions", "Compress at a depth of at least 2 inches (5 cm) at a rate of 100 to 120 compressions per minute.", (short) 1));
        lessons.save(new TrainingLesson(cpr.getId(), "AED Operation", "Turn on AED, apply pads to bare dry chest (upper right, lower left side), follow voice prompts, stand clear when shocking.", (short) 2));

        TrainingCourse bleed = courses.save(new TrainingCourse(
            "Severe Bleeding Control & Tourniquet Application",
            "Rapid response methods for traumatic bleeding and shock prevention.",
            false
        ));
        lessons.save(new TrainingLesson(bleed.getId(), "Direct Pressure", "Apply firm, continuous direct pressure with sterile gauze or clean cloth directly onto the bleeding site.", (short) 1));
        lessons.save(new TrainingLesson(bleed.getId(), "Tourniquet Guidelines", "Place tourniquet 2 to 3 inches above the wound on an extremity (not over a joint). Tighten until bleeding stops.", (short) 2));

        TrainingCourse triage = courses.save(new TrainingCourse(
            "Emergency Scene Safety & START Triage",
            "Simple Triage and Rapid Treatment principles for multi-casualty incidents.",
            false
        ));
        lessons.save(new TrainingLesson(triage.getId(), "Assessing Scene Safety", "Confirm scene is safe before entering. Check for hazards (traffic, fire, electrical wires).", (short) 1));
        lessons.save(new TrainingLesson(triage.getId(), "START Triage Categories", "Red: Immediate life threat. Yellow: Delayed urgent care. Green: Minor walking wounded. Black: Deceased/Expectant.", (short) 2));
    }

    public List<TrainingDtos.CourseSummary> listCourses(UUID userId) {
        ensureDefaultCourses();
        return courses.findAll().stream().map(c -> {
            List<TrainingLesson> lessonList = lessons.findByCourseIdOrderBySortOrderAsc(c.getId());
            Optional<TrainingResult> userResult = results.findByUserIdAndCourseId(userId, c.getId());
            BigDecimal score = userResult.isPresent() ? userResult.get().getScore() : null;
            boolean passed = score != null && score.compareTo(BigDecimal.valueOf(80.0)) >= 0;
            String certCode = passed ? certCodeFor(courseKey(c.getTitle())) : null;
            java.time.Instant completedAt = userResult.isPresent() ? userResult.get().getCompletedAt() : null;
            return new TrainingDtos.CourseSummary(
                c.getId(),
                c.getTitle(),
                c.getDescription(),
                c.isMockContent(),
                lessonList.size(),
                score,
                passed,
                certCode,
                completedAt
            );
        }).toList();
    }

    public TrainingDtos.CourseDetail getCourseDetail(UUID courseId) {
        java.util.Objects.requireNonNull(courseId, "courseId must not be null");
        TrainingCourse course = courses.findById(courseId)
            .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));
        List<TrainingDtos.LessonDto> lessonDtos = lessons.findByCourseIdOrderBySortOrderAsc(courseId).stream()
            .map(l -> new TrainingDtos.LessonDto(l.getId(), l.getCourseId(), l.getTitle(), l.getContent(), l.getSortOrder()))
            .toList();

        List<TrainingDtos.QuizQuestion> questions = getQuestionsForCourse(course.getTitle());
        return new TrainingDtos.CourseDetail(course.getId(), course.getTitle(), course.getDescription(), lessonDtos, questions);
    }

    @Transactional
    public TrainingDtos.QuizResult submitQuiz(UUID userId, UUID courseId, List<Integer> submittedAnswers) {
        java.util.Objects.requireNonNull(courseId, "courseId must not be null");
        TrainingCourse course = courses.findById(courseId)
            .orElseThrow(() -> new IllegalArgumentException("Course not found: " + courseId));

        String key = courseKey(course.getTitle());
        List<Integer> answerKey = ANSWER_KEYS.getOrDefault(key, List.of(0, 0, 0));

        int total = answerKey.size();
        int correct = 0;
        for (int i = 0; i < total; i++) {
            if (i < submittedAnswers.size() && submittedAnswers.get(i).equals(answerKey.get(i))) {
                correct++;
            }
        }

        BigDecimal score = BigDecimal.valueOf((correct * 100.0) / total).setScale(2, RoundingMode.HALF_UP);
        boolean passed = score.compareTo(BigDecimal.valueOf(80.0)) >= 0;

        TrainingResult result = results.findByUserIdAndCourseId(userId, courseId)
            .orElseGet(() -> new TrainingResult(userId, courseId, score));
        result.setScore(score);
        result.setCompletedAt(Instant.now());
        results.save(result);

        String certCode = null;
        if (passed) {
            certCode = certCodeFor(key);
            awardCertification(userId, certCode);
        }

        String feedback = passed
            ? "Congratulations! You passed with " + score + "%. Certification has been recorded."
            : "You scored " + score + "%. A score of 80% or higher is required to pass. Please review the material and try again.";

        return new TrainingDtos.QuizResult(score, passed, feedback, certCode);
    }

    private void awardCertification(UUID userId, String certCode) {
        try {
            // Find certification id from certifications table or insert if missing
            List<Short> certIds = jdbc.query("SELECT id FROM certifications WHERE code = ?", (rs, rowNum) -> rs.getShort("id"), certCode);
            short certId;
            if (certIds.isEmpty()) {
                Short createdId = jdbc.queryForObject("INSERT INTO certifications (code, label) VALUES (?, ?) RETURNING id",
                    Short.class, certCode, certCode.replace('_', ' ') + " Certification");
                certId = (createdId != null) ? createdId : (short) 1;
            } else {
                Short existingId = certIds.get(0);
                certId = (existingId != null) ? existingId : (short) 1;
            }

            // Upsert into volunteer_certifications if user is a volunteer
            Instant expiresAt = Instant.now().plus(730, ChronoUnit.DAYS); // 2 years validity
            jdbc.update("""
                INSERT INTO volunteer_certifications (volunteer_id, certification_id, verified_at, expires_at)
                VALUES (?, ?, now(), ?)
                ON CONFLICT (volunteer_id, certification_id)
                DO UPDATE SET verified_at = now(), expires_at = EXCLUDED.expires_at
                """, userId, certId, expiresAt);
        } catch (Exception ignored) {
            // User may not have volunteer_profile yet
        }
    }

    private String courseKey(String title) {
        if (title.toUpperCase().contains("CPR")) return "CPR_AED";
        if (title.toUpperCase().contains("BLEED")) return "BLEEDING";
        return "TRIAGE";
    }

    private String certCodeFor(String key) {
        return switch (key) {
            case "CPR_AED" -> "CPR_AED";
            case "BLEEDING" -> "FIRST_AID";
            default -> "PARAMEDIC";
        };
    }

    private List<TrainingDtos.QuizQuestion> getQuestionsForCourse(String title) {
        String key = courseKey(title);
        if ("CPR_AED".equals(key)) {
            return List.of(
                new TrainingDtos.QuizQuestion(0, "What is the recommended adult chest compression rate?",
                    List.of("60-80 compressions/min", "100-120 compressions/min", "140-160 compressions/min")),
                new TrainingDtos.QuizQuestion(1, "Where should AED pads be placed on an adult victim?",
                    List.of("Upper right chest and lower left side", "Center of chest and lower back", "Both on the upper chest")),
                new TrainingDtos.QuizQuestion(2, "What is the standard ratio of chest compressions to rescue breaths?",
                    List.of("15 compressions to 2 breaths", "20 compressions to 1 breath", "30 compressions to 2 breaths"))
            );
        } else if ("BLEEDING".equals(key)) {
            return List.of(
                new TrainingDtos.QuizQuestion(0, "What is the initial first step to control severe external bleeding?",
                    List.of("Apply direct pressure with clean dressing", "Immediately apply ice", "Wash with warm water")),
                new TrainingDtos.QuizQuestion(1, "Where should a tourniquet be applied relative to an extremity wound?",
                    List.of("Directly over the wound", "2 to 3 inches above the wound (not over a joint)", "Below the wound")),
                new TrainingDtos.QuizQuestion(2, "How should you position and care for a patient showing signs of shock?",
                    List.of("Keep warm, calm, and lie flat if safe", "Have them stand up and walk", "Offer solid food immediately"))
            );
        } else {
            return List.of(
                new TrainingDtos.QuizQuestion(0, "In START triage, a patient with airway obstruction relieved by positioning is categorized as:",
                    List.of("Green (Minor)", "Yellow (Delayed)", "Red (Immediate)")),
                new TrainingDtos.QuizQuestion(1, "What is the very first step before approaching any emergency victim?",
                    List.of("Ensure the scene is safe for responders", "Administer oxygen", "Check identification")),
                new TrainingDtos.QuizQuestion(2, "Walking wounded patients who can follow commands are initially tagged as:",
                    List.of("Red (Immediate)", "Green (Minor)", "Yellow (Delayed)"))
            );
        }
    }
}
