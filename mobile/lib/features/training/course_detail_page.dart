// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../auth/auth_controller.dart';
import '../volunteer/volunteer_controller.dart';
import 'certificate_dialog.dart';
import 'training_controller.dart';
import 'training_repository.dart';

class CourseDetailPage extends ConsumerStatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  final Map<int, int> _selectedAnswers = {};
  bool _submitting = false;

  Future<void> _submit(String courseTitle, List<QuizQuestionItem> questions) async {
    final l = AppLocalizations.of(context);
    if (_selectedAnswers.length < questions.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.text('required'))));
      return;
    }

    final answers = List.generate(
      questions.length,
      (i) => _selectedAnswers[i] ?? 0,
    );

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(trainingRepositoryProvider)
          .submitQuiz(widget.courseId, answers);

      ref.invalidate(coursesListProvider);
      ref.invalidate(volunteerDashboardProvider);

      if (!mounted) return;

      final session = ref.read(sessionControllerProvider).value;
      final userName =
          (session?.displayName != null && session!.displayName.trim().isNotEmpty)
              ? session.displayName
              : 'Mohamed Tamer';

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                result.passed
                    ? Icons.workspace_premium_rounded
                    : Icons.warning_amber_rounded,
                color: result.passed ? const Color(0xFFC5A059) : AppTheme.warning,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.passed
                      ? (l.isArabic ? 'تهانينا! تم اجتياز الاختبار بنجاح' : 'Congratulations! Quiz Passed')
                      : l.text('quizFailed'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: result.passed
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      result.passed ? Icons.check_circle : Icons.info_outline,
                      color: result.passed ? AppTheme.success : AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.format('quizScore', {
                        'score': result.score.toStringAsFixed(0),
                      }),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: result.passed ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(result.feedback),
              if (result.passed) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5A059),
                      foregroundColor: const Color(0xFF0F1E36),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.workspace_premium, size: 20),
                    label: Text(
                      l.isArabic
                          ? 'عرض واستلام الشهادة المعتمدة 📜'
                          : 'View Official Certificate 📜',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      showOfficialCertificate(
                        context,
                        recipientName: userName,
                        courseTitle: courseTitle,
                        score: result.score,
                        certificateId: result.certificationCode,
                        isArabic: l.isArabic,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.text('backToHome')),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.text('error'))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final detailAsync = ref.watch(courseDetailProvider(widget.courseId));

    return Scaffold(
      appBar: AppBar(title: Text(l.text('training'))),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => PageFailure(
          title: l.text('training'),
          message: l.text('error'),
          retryLabel: l.text('retry'),
          onRetry: () => ref.invalidate(courseDetailProvider(widget.courseId)),
        ),
        data: (course) => QaPageFrame(
          child: ListView(
            children: [
              Text(
                course.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                course.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l.text('courseLessons')),
              const SizedBox(height: 8),
              ...course.lessons.map(
                (lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.blue.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.format('lessonNumber', {
                                  'number': lesson.sortOrder.toString(),
                                }),
                                style: const TextStyle(
                                  color: AppTheme.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lesson.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l.text('quizTitle')),
              const SizedBox(height: 8),
              ...course.quiz.asMap().entries.map((entry) {
                final qIndex = entry.key;
                final q = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: QaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${qIndex + 1}. ${q.question}',
                          style: Theme.of(context).textTheme.titleMedium,
                          textDirection:
                              RegExp(r'[\u0600-\u06FF]').hasMatch(q.question)
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                        const SizedBox(height: 8),
                        ...q.options.asMap().entries.map((opt) {
                          final optIndex = opt.key;
                          final optText = opt.value;
                          final selected = _selectedAnswers[qIndex] == optIndex;
                          return InkWell(
                            onTap: _submitting
                                ? null
                                : () => setState(
                                    () => _selectedAnswers[qIndex] = optIndex,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: optIndex,
                                    groupValue: _selectedAnswers[qIndex],
                                    onChanged: _submitting
                                        ? null
                                        : (val) => setState(
                                            () =>
                                                _selectedAnswers[qIndex] = val!,
                                          ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      optText,
                                      style: TextStyle(
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      textDirection:
                                          RegExp(
                                            r'[\u0600-\u06FF]',
                                          ).hasMatch(optText)
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submitting ? null : () => _submit(course.title, course.quiz),
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.text('submitQuiz')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
