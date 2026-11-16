import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';
import 'package:smartaid_mobile/core/network/api_client.dart';
import 'package:smartaid_mobile/core/theme/app_theme.dart';
import 'package:smartaid_mobile/features/auth/auth_repository.dart';
import 'package:smartaid_mobile/features/ems/ems_controller.dart';
import 'package:smartaid_mobile/features/ems/ems_dashboard_page.dart';
import 'package:smartaid_mobile/features/ems/ems_repository.dart';
import 'package:smartaid_mobile/features/healthcare/organization_portal_page.dart';
import 'package:smartaid_mobile/features/home/home_page.dart';
import 'package:smartaid_mobile/features/incidents/incidents_controller.dart';
import 'package:smartaid_mobile/features/resources/resource_controller.dart';
import 'package:smartaid_mobile/features/resources/resource_repository.dart';

class _PopulatedFakeApiClient implements ApiClient {
  @override
  Future<Response<T>> get<T>(String path) async {
    final List<dynamic> data = switch (path) {
      '/api/hospitals' => [
        {
          'id': 'h1',
          'name': 'DEMO • Cairo Central Trauma Hospital Long Name',
          'latitude': 30.0444,
          'longitude': 31.2357,
        },
      ],
      '/api/handovers/pending' => [
        {
          'id': 'ho1',
          'triageSummary': 'Acute chest pain • Priority CRITICAL',
          'vitalSigns': 'BP 90/60 • HR 122 • SpO2 93%',
          'interventionsAdministered': 'Oxygen 4L/min, IV access',
        },
      ],
      '/api/pharmacies/orders/pending' => [
        {
          'id': 'o1', // Short ID (<8 chars) to test RangeError safety
          'quantity': 2,
          'deliveryAddress': '14 Tahrir Sq, Cairo',
          'orderStatus': 'PENDING',
        },
      ],
      '/api/medical-deliveries' => [
        {
          'id': 'd1',
          'trackingCode': 'TRK-SHORT',
          'deliveryStatus': 'IN_TRANSIT',
          'etaMinutes': 12,
        },
      ],
      '/api/blood-banks/inventory' => [
        {'id': 'inv1', 'bloodGroup': 'AB-', 'unitsAvailable': 3},
        {'id': 'inv2', 'bloodGroup': 'O+', 'unitsAvailable': 18},
      ],
      '/api/blood-requests' => [
        {
          'id': 'br1',
          'bloodGroup': 'O-',
          'unitsRequested': 2,
          'urgency': 'CRITICAL',
          'status': 'CANCELLED',
        },
      ],
      '/api/lab-appointments' => [
        {
          'id': 'l1', // Short ID (<8 chars) to test RangeError safety
          'status': 'SCHEDULED',
          'resultSummary': null,
        },
      ],
      '/api/provider-appointments' => [
        {
          'id': 'pa1',
          'appointmentType': 'TELEMEDICINE',
          'chiefComplaint': 'Follow-up cardiac evaluation',
          'status': 'CANCELLED',
        },
      ],
      _ => <dynamic>[],
    };
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data as T,
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

class _FakeHospitalsNotifier extends VerifiedHospitalsNotifier {
  @override
  Future<List<HospitalResource>> build() async => const [
    HospitalResource(
      id: 'h1',
      name: 'DEMO • مستشفى الطوارئ المركزي التخصصي بالقاهرة',
      latitude: 30.0444,
      longitude: 31.2357,
      updatedAt: null,
    ),
  ];
}

Widget _wrapApp(
  Widget child, {
  Locale locale = const Locale('ar'),
  double textScale = 1.0,
}) {
  return MaterialApp(
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
      child: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'OrganizationPortalPage Pharmacist handles short order IDs without RangeError on 320px/1.4x',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const session = Session(
        email: 'demo.pharmacist@smartaid.local',
        displayName: 'Demo Pharmacist',
        roles: ['PHARMACIST'],
        accessToken: 't',
        refreshToken: 'r',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_PopulatedFakeApiClient()),
          ],
          child: _wrapApp(
            const OrganizationPortalPage(session: session),
            locale: const Locale('ar'),
            textScale: 1.4,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('o1'), findsOneWidget);
    },
  );

  testWidgets(
    'OrganizationPortalPage Lab handles short appointment IDs without RangeError on 320px/1.4x',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const session = Session(
        email: 'demo.lab@smartaid.local',
        displayName: 'Demo Lab',
        roles: ['LAB_STAFF'],
        accessToken: 't',
        refreshToken: 'r',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_PopulatedFakeApiClient()),
          ],
          child: _wrapApp(
            const OrganizationPortalPage(session: session),
            locale: const Locale('ar'),
            textScale: 1.4,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('l1'), findsOneWidget);
    },
  );

  testWidgets(
    'OrganizationPortalPage Blood Bank shows CANCELLED status accurately and does not overflow at 1.4x',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const session = Session(
        email: 'demo.bloodbank@smartaid.local',
        displayName: 'Demo Blood Bank',
        roles: ['BLOOD_BANK_STAFF'],
        accessToken: 't',
        refreshToken: 'r',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_PopulatedFakeApiClient()),
          ],
          child: _wrapApp(
            const OrganizationPortalPage(session: session),
            locale: const Locale('en'),
            textScale: 1.4,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('FULFILLED'), findsNothing);
    },
  );

  testWidgets(
    'OrganizationPortalPage Doctor shows CANCELLED status accurately instead of CONFIRMED',
    (tester) async {
      const session = Session(
        email: 'demo.doctor@smartaid.local',
        displayName: 'Demo Doctor',
        roles: ['DOCTOR'],
        accessToken: 't',
        refreshToken: 'r',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_PopulatedFakeApiClient()),
          ],
          child: _wrapApp(
            const OrganizationPortalPage(session: session),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsNothing);
    },
  );

  testWidgets(
    'HomePage nearby hospitals summary renders without overflow at 320px/1.4x in Arabic RTL',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const session = Session(
        email: 'demo.user@smartaid.local',
        displayName: 'Demo Citizen',
        roles: ['USER'],
        accessToken: 't',
        refreshToken: 'r',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myIncidentsProvider.overrideWith((ref) => Future.value(const [])),
            verifiedHospitalsProvider.overrideWith(_FakeHospitalsNotifier.new),
          ],
          child: _wrapApp(
            const HomePage(session: session),
            locale: const Locale('ar'),
            textScale: 1.4,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.text('DEMO • مستشفى الطوارئ المركزي التخصصي بالقاهرة'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EmsDashboardPage multi-responder sheet renders without overflow on Landscape 640x360',
    (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const session = Session(
        email: 'demo.ems@smartaid.local',
        displayName: 'Demo EMS',
        roles: ['EMS'],
        accessToken: 't',
        refreshToken: 'r',
      );

      final mockDashboard = EmsDashboard(
        activeIncidents: 1,
        criticalIncidents: 1,
        incidents: const [
          EmsIncident(
            id: 'INC-LANDSCAPE-01',
            emergencyType: 'CARDIAC',
            status: 'SEARCHING',
            priority: 'CRITICAL',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emsDashboardProvider.overrideWith(
              (ref) => Future.value(mockDashboard),
            ),
          ],
          child: _wrapApp(
            const EmsDashboardPage(session: session),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(OutlinedButton, 'Multi-Responder Dispatch');
      await tester.scrollUntilVisible(
        btn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
