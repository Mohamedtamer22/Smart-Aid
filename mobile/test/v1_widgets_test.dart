import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';
import 'package:smartaid_mobile/core/theme/app_theme.dart';
import 'package:smartaid_mobile/shared/widgets/pulsing_sos_button.dart';
import 'package:smartaid_mobile/shared/widgets/quick_role_switcher.dart';
import 'package:smartaid_mobile/features/auth/auth_repository.dart';
import 'package:smartaid_mobile/features/ems/ems_controller.dart';
import 'package:smartaid_mobile/features/ems/ems_dashboard_page.dart';
import 'package:smartaid_mobile/features/ems/ems_repository.dart';

void main() {
  testWidgets(
    'PulsingSosButton renders correctly and triggers onPressed callback',
    (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: Center(
              child: PulsingSosButton(
                onPressed: () => pressed = true,
                label: 'SOS',
              ),
            ),
          ),
        ),
      );

      // Initial render
      expect(find.text('SOS'), findsOneWidget);
      expect(find.byIcon(Icons.emergency_outlined), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Tap button
      await tester.tap(find.text('SOS'));
      await tester.pump();

      expect(pressed, isTrue);
    },
  );

  testWidgets('QuickRoleSwitcher renders properly with all options', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.build(),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: QuickRoleSwitcher()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart Aid V2 Workspace'), findsOneWidget);
    expect(find.text('EMS Dispatcher'), findsOneWidget);
    expect(find.text('Hospital Staff'), findsOneWidget);
    expect(find.text('Pharmacist'), findsOneWidget);
    expect(find.text('Blood Bank Staff'), findsOneWidget);
    expect(find.text('Laboratory Staff'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('System Administrator'), findsOneWidget);
    expect(find.byType(QuickRoleSwitcher), findsOneWidget);
  });

  testWidgets('EmsDashboardPage renders correctly with incident cards', (
    tester,
  ) async {
    final mockDashboard = EmsDashboard(
      activeIncidents: 2,
      criticalIncidents: 1,
      incidents: const [
        EmsIncident(
          id: 'test-1',
          emergencyType: 'CARDIAC',
          status: 'SEARCHING',
          priority: 'CRITICAL',
        ),
        EmsIncident(
          id: 'test-2',
          emergencyType: 'MEDICAL',
          status: 'RESPONDER_ASSIGNED',
          priority: 'STANDARD',
        ),
      ],
    );

    const testSession = Session(
      email: 'demo.ems@smartaid.local',
      displayName: 'Demo EMS',
      roles: ['EMS', 'USER'],
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emsDashboardProvider.overrideWith(
            (ref) => Future.value(mockDashboard),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const EmsDashboardPage(session: testSession),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EmsDashboardPage), findsOneWidget);
    expect(find.text('مركز تحكم الإسعاف'), findsNWidgets(2));
    expect(find.text('2 الطوارئ النشطة'), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
  });
}
