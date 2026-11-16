import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';
import 'package:smartaid_mobile/core/theme/app_theme.dart';
import 'package:smartaid_mobile/features/onboarding/onboarding_page.dart';

void main() {
  Widget createTestApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.build(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }

  testWidgets('OnboardingPage renders slides and navigation controls', (
    tester,
  ) async {
    await tester.pumpWidget(createTestApp(const OnboardingPage()));
    await tester.pumpAndSettle();

    // Verify first slide content
    expect(find.byIcon(Icons.emergency), findsOneWidget);
    expect(find.text('Instant Emergency Alert'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next to advance
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Verify second slide content
    expect(find.text('Smart ER Decision Support'), findsOneWidget);
  });
}
