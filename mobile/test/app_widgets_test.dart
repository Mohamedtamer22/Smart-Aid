import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/core/theme/app_theme.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';
import 'package:smartaid_mobile/shared/widgets/app_widgets.dart';

void main() {
  testWidgets('Brand mark remains labelled and visually complete', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: Center(
            child: BrandMark(
              size: 80,
              label: 'Smart Aid emergency coordination',
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_rounded), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(BrandMark)),
      matchesSemantics(
        label: 'Smart Aid emergency coordination',
        isImage: true,
      ),
    );
  });

  testWidgets('Quality card preserves a defined outline and shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const QaCard(child: Text('Content')),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.elevation, 0);
    expect(card.shape, isA<RoundedRectangleBorder>());
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('Presentation components communicate hierarchy and score', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: QaPageFrame(
            child: Column(
              children: [
                QaHeroCard(
                  eyebrow: 'Decision support',
                  title: 'Recommended destination',
                  message: 'Based on available demonstration data',
                  icon: Icons.local_hospital_outlined,
                ),
                SizedBox(height: 12),
                QaScoreBar(label: 'Capability', score: 92),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Recommended destination'), findsOneWidget);
    expect(find.text('92'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  test('Smart ER explanations are ready for Arabic presentation', () {
    const arabic = AppLocalizations(Locale('ar'));
    expect(arabic.text('smartErReasonSpecialty'), isNotEmpty);
    expect(
      arabic.format('smartErReasonReportedCongestion', {'value': '24%'}),
      contains('24%'),
    );
  });
}
