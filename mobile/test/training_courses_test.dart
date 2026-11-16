import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';
import 'package:smartaid_mobile/core/theme/app_theme.dart';
import 'package:smartaid_mobile/features/training/training_controller.dart';
import 'package:smartaid_mobile/features/training/training_courses_page.dart';
import 'package:smartaid_mobile/features/training/training_repository.dart';

void main() {
  testWidgets('TrainingCoursesPage renders courses list and status badges', (
    tester,
  ) async {
    final mockCourses = [
      const CourseSummary(
        id: 'cpr-01',
        title: 'Adult CPR & AED',
        description: 'Learn lifesaving compressions and AED operation',
        lessonCount: 2,
        userScore: 100.0,
        passed: true,
      ),
      const CourseSummary(
        id: 'bleed-02',
        title: 'Severe Bleeding Control',
        description: 'Rapid response methods for traumatic bleeding',
        lessonCount: 2,
        userScore: 65.0,
        passed: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coursesListProvider.overrideWith((ref) => Future.value(mockCourses)),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const TrainingCoursesPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Adult CPR & AED'), findsOneWidget);
    expect(find.text('Severe Bleeding Control'), findsOneWidget);
    expect(find.textContaining('Certified'), findsOneWidget);
    expect(find.textContaining('65%'), findsOneWidget);
    expect(find.textContaining('View Official Certificate'), findsOneWidget);
  });
}
