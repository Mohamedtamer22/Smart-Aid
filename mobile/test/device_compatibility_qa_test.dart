import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';
import 'package:smartaid_mobile/core/theme/app_theme.dart';
import 'package:smartaid_mobile/features/auth/auth_repository.dart';
import 'package:smartaid_mobile/features/auth/login_page.dart';
import 'package:smartaid_mobile/features/emergency/sos_confirmation_sheet.dart';
import 'package:smartaid_mobile/features/emergency/triage_sheet.dart';
import 'package:smartaid_mobile/features/ems/ems_controller.dart';
import 'package:smartaid_mobile/features/ems/ems_repository.dart';
import 'package:smartaid_mobile/features/home/home_page.dart';
import 'package:smartaid_mobile/features/incidents/incidents_controller.dart';
import 'package:smartaid_mobile/features/profile/settings_page.dart';
import 'package:smartaid_mobile/features/profile/user_profile_page.dart';

const testSession = Session(
  email: 'test@smartaid.local',
  displayName: 'Test User',
  roles: ['USER'],
  accessToken: 'mock-access',
  refreshToken: 'mock-refresh',
);

Widget createTestApp({
  required Widget child,
  Locale locale = const Locale('ar'),
  double textScale = 1.0,
  List<dynamic> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      myIncidentsProvider.overrideWith((ref) => Future.value([])),
      emsDashboardProvider.overrideWith(
        (ref) => Future.value(
          const EmsDashboard(
            activeIncidents: 1,
            criticalIncidents: 0,
            incidents: [],
          ),
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.build(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Material(child: child),
      ),
    ),
  );
}

void main() {
  final deviceProfiles = <String, Size>{
    'Compact Phone (320x568)': const Size(320, 568),
    'Budget Android (360x640)': const Size(360, 640),
    'Standard Phone (390x844)': const Size(390, 844),
    'Modern Tall Phone (412x915)': const Size(412, 915),
    'Landscape Phone (640x360)': const Size(640, 360),
    'Tablet (768x1024)': const Size(768, 1024),
  };

  group('QA Device Compatibility & Responsiveness Matrix', () {
    for (final entry in deviceProfiles.entries) {
      final deviceName = entry.key;
      final size = entry.value;

      testWidgets('LoginPage renders without overflow on $deviceName', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(child: const LoginPage()));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(LoginPage), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow or crash on $deviceName',
        );
      });

      testWidgets('HomePage renders without overflow on $deviceName', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const HomePage(session: testSession)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(HomePage), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow or crash on $deviceName',
        );
      });

      testWidgets('UserProfilePage renders without overflow on $deviceName', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const UserProfilePage(session: testSession)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(UserProfilePage), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on $deviceName',
        );
      });

      testWidgets(
        'SosConfirmationSheet renders without overflow on $deviceName',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            createTestApp(child: const SosConfirmationSheet()),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(SosConfirmationSheet), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow on $deviceName',
          );
        },
      );

      testWidgets('TriageSheet renders without overflow on $deviceName', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(child: const TriageSheet()));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TriageSheet), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on $deviceName',
        );
      });

      testWidgets('SettingsPage renders without overflow on $deviceName', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SettingsPage), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on $deviceName',
        );
      });
    }

    testWidgets(
      'Accessibility: Large Font Scale (1.4x) does not cause layout overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const LoginPage(), textScale: 1.4),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason:
              'Accessibility 1.4x text scale caused layout overflow on LoginPage',
        );
      },
    );

    testWidgets(
      'Bilingual / RTL check: English (LTR) vs Arabic (RTL) renders correctly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Test English LTR
        await tester.pumpWidget(
          createTestApp(
            child: const HomePage(session: testSession),
            locale: const Locale('en'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Home'), findsWidgets);
        expect(tester.takeException(), isNull);

        // Test Arabic RTL
        await tester.pumpWidget(
          createTestApp(
            child: const HomePage(session: testSession),
            locale: const Locale('ar'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
