import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';
import 'package:smartaid_mobile/core/network/api_client.dart';
import 'package:smartaid_mobile/features/auth/auth_repository.dart';
import 'package:smartaid_mobile/features/auth/login_page.dart';
import 'package:smartaid_mobile/features/healthcare/connected_healthcare_page.dart';
import 'package:smartaid_mobile/features/healthcare/healthcare_repository.dart';
import 'package:smartaid_mobile/features/healthcare/organization_portal_page.dart';
import 'package:smartaid_mobile/features/offline/offline_emergency_page.dart';
import 'package:smartaid_mobile/features/offline/offline_emergency_service.dart';

class _FakeApiClient implements ApiClient {
  @override
  Future<Response<T>> get<T>(String path) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: <dynamic>[] as T,
    );
  }

  @override
  Future<Response<T>> post<T>(String path, {Object? data, Options? options}) =>
      get<T>(path);

  @override
  Future<Response<T>> put<T>(String path, {Object? data}) => get<T>(path);

  @override
  Future<Response<T>> patch<T>(String path, {Object? data}) => get<T>(path);

  @override
  Future<Response<T>> delete<T>(String path) => get<T>(path);
}

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('OfflineEmergencyService persists drafts with unique idempotency keys', () async {
    final service = OfflineEmergencyService();
    final first = await service.enqueueIncident(
      emergencyType: 'CARDIAC',
      latitude: 30.0444,
      longitude: 31.2357,
      notes: 'Chest pain near metro',
    );
    final second = await service.enqueueIncident(
      emergencyType: 'TRAUMA',
      latitude: 30.0500,
      longitude: 31.2400,
      notes: 'Fall injury',
    );

    expect(first.idempotencyKey, isNotEmpty);
    expect(second.idempotencyKey, isNot(first.idempotencyKey));

    final queue = await service.loadQueue();
    expect(queue.length, 2);
    expect(queue.first.emergencyType, 'TRAUMA');

    await service.clearQueue();
    expect(await service.loadQueue(), isEmpty);
  });

  testWidgets('OfflineEmergencyPage renders guides and saves local draft on compact screen', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(child: _wrap(const OfflineEmergencyPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline Emergency Mode'), findsOneWidget);
    expect(find.text('Adult Hands-Only CPR (Cardiac Arrest)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Save Offline Draft'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Save Offline Draft'), findsOneWidget);

    await tester.tap(find.text('Save Offline Draft'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sync Pending (1)'), findsOneWidget);
  });

  testWidgets('OfflineEmergencyPage renders cleanly in Arabic RTL', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: _wrap(const OfflineEmergencyPage(), locale: const Locale('ar')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('وضع الطوارئ دون إنترنت'), findsOneWidget);
    expect(find.text('السيطرة على النزيف الحاد'), findsOneWidget);
  });

  testWidgets('ConnectedHealthcarePage renders pharmacies, blood banks, labs, and providers tabs', (tester) async {
    final overrides = [
      pharmaciesProvider.overrideWith(
        (ref) async => const [
          PharmacyItem(
            id: 'p1',
            name: 'DEMO • Nile 24/7 Emergency Pharmacy',
            address: '14 Tahrir Sq',
            phone: '1001',
            openingHours: '24/7',
            emergencySuppliesAvailable: true,
          ),
        ],
      ),
      bloodBanksProvider.overrideWith(
        (ref) async => const [
          BloodBankItem(
            id: 'b1',
            name: 'DEMO • Central Blood Bank',
            address: 'Dokki',
            phone: '2001',
          ),
        ],
      ),
      laboratoriesProvider.overrideWith(
        (ref) async => const [
          LaboratoryItem(
            id: 'l1',
            name: 'DEMO • Cairo Diagnostics Lab',
            address: 'Dokki',
            phone: '3001',
          ),
        ],
      ),
      medicalProvidersProvider.overrideWith(
        (ref) async => const [
          MedicalProviderItem(
            id: 'm1',
            name: 'DEMO • Dr. Amina Hassan',
            providerType: 'DOCTOR',
            specialty: 'Cardiology',
            address: 'Mohandessin',
            telemedicineEnabled: true,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: _wrap(const ConnectedHealthcarePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DEMO • Nile 24/7 Emergency Pharmacy'), findsOneWidget);

    await tester.tap(find.text('Blood Banks'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO • Central Blood Bank'), findsOneWidget);

    await tester.tap(find.text('Laboratories'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO • Cairo Diagnostics Lab'), findsOneWidget);

    await tester.ensureVisible(find.text('Medical Services'));
    await tester.tap(find.text('Medical Services'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO • Dr. Amina Hassan'), findsOneWidget);
  });

  testWidgets('LoginPage displays V2.0 badge and all 9 demo role chips in Arabic RTL', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: _wrap(const LoginPage(), locale: const Locale('ar')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('V2.0'), findsOneWidget);
    expect(find.text('مواطن'), findsOneWidget);
    expect(find.text('متطوع'), findsOneWidget);
    expect(find.text('إسعاف'), findsOneWidget);
    expect(find.text('مستشفى'), findsOneWidget);
    expect(find.text('صيدلي'), findsOneWidget);
    expect(find.text('بنك دم'), findsOneWidget);
    expect(find.text('معمل'), findsOneWidget);
    expect(find.text('طبيب'), findsOneWidget);
    expect(find.text('مدير النظام'), findsOneWidget);
  });

  testWidgets('OrganizationPortalPage renders header cleanly for Pharmacist role', (tester) async {
    const pharmacistSession = Session(
      email: 'demo.pharmacist@smartaid.local',
      displayName: 'Demo Pharmacist',
      roles: ['PHARMACIST'],
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient()),
        ],
        child: _wrap(
          const OrganizationPortalPage(session: pharmacistSession),
          locale: const Locale('ar'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('بوابة الصيدلي والتوصيل'), findsOneWidget);
    expect(find.byType(OrganizationPortalPage), findsOneWidget);
  });
}
