import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../auth/auth_controller.dart';
import 'certificate_dialog.dart';
import 'course_detail_page.dart';
import 'training_controller.dart';
import 'training_repository.dart';

class TrainingCoursesPage extends ConsumerWidget {
  const TrainingCoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final courses = ref.watch(coursesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('training')),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(coursesListProvider),
            icon: const Icon(Icons.refresh),
            tooltip: l.text('refresh'),
          ),
        ],
      ),
      body: QaPageFrame(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(coursesListProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              QaPageHeader(
                title: l.text('training'),
                subtitle: l.text('trainingSubtitle'),
              ),
              const SizedBox(height: 16),
              QaHeroCard(
                eyebrow: l.text('training'),
                title: l.text('trainingSubtitle'),
                message: l.text('disclaimer'),
                icon: Icons.school_outlined,
                color: AppTheme.blue,
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l.text('courses')),
              const SizedBox(height: 10),
              courses.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => PageFailure(
                  title: l.text('training'),
                  message: l.text('error'),
                  retryLabel: l.text('retry'),
                  onRetry: () => ref.invalidate(coursesListProvider),
                ),
                data: (items) => items.isEmpty
                    ? EmptyState(
                        icon: Icons.school_outlined,
                        title: l.text('training'),
                        message: l.text('unavailableData'),
                      )
                    : Column(
                        children: items
                            .map(
                              (course) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CourseCard(course: course),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course});
  final CourseSummary course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider).value;
    final recipientName =
        (session?.displayName != null && session!.displayName.trim().isNotEmpty)
            ? session.displayName
            : 'Mohamed Tamer';

    return QaCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CourseDetailPage(courseId: course.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (course.passed ? AppTheme.success : AppTheme.blue)
                              .withValues(alpha: .16),
                          (course.passed ? AppTheme.success : AppTheme.blue)
                              .withValues(alpha: .06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: (course.passed ? AppTheme.success : AppTheme.blue)
                            .withValues(alpha: .22),
                      ),
                    ),
                    child: Icon(
                      course.passed
                          ? Icons.verified_rounded
                          : Icons.menu_book_rounded,
                      color: course.passed ? AppTheme.success : AppTheme.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        if (course.passed)
                          StatusPill(
                            label: l.isArabic
                                ? 'ناجح معتمد (${course.userScore?.toStringAsFixed(0) ?? '100'}%)'
                                : 'Certified (${course.userScore?.toStringAsFixed(0) ?? '100'}%)',
                            color: AppTheme.success,
                          )
                        else if (course.userScore != null)
                          StatusPill(
                            label: l.isArabic
                                ? '${course.userScore!.toStringAsFixed(0)}% (لم يجتز)'
                                : '${course.userScore!.toStringAsFixed(0)}% (Failed)',
                            color: AppTheme.warning,
                          )
                        else
                          StatusPill(
                            label: l.isArabic ? 'جديد / لم يختبر' : 'New / Untested',
                            color: AppTheme.blue,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (course.passed) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5A059),
                      foregroundColor: const Color(0xFF0F1E36),
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                    label: Text(
                      l.isArabic ? 'عرض الشهادة المعتمدة 📜' : 'View Official Certificate 📜',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    onPressed: () {
                      showOfficialCertificate(
                        context,
                        recipientName: recipientName,
                        courseTitle: course.title,
                        score: course.userScore ?? 100.0,
                        date: course.completedAt,
                        certificateId: course.certificationCode,
                        isArabic: l.isArabic,
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.library_books_outlined,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${course.lessonCount} ${l.text('courseLessons')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        course.passed
                            ? (l.isArabic ? 'مراجعة الاختبار' : 'Review Quiz')
                            : (course.userScore != null
                                ? (l.isArabic ? 'إعادة الاختبار' : 'Retake Quiz')
                                : l.text('takeQuiz')),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.blue,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppTheme.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
