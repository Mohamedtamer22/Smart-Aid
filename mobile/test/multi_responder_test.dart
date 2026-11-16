import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';
import 'package:smartaid_mobile/core/theme/app_theme.dart';
import 'package:smartaid_mobile/features/auth/auth_repository.dart';
import 'package:smartaid_mobile/features/emergency/active_emergency_page.dart';
import 'package:smartaid_mobile/features/emergency/emergency_repository.dart';
import 'package:smartaid_mobile/features/ems/ems_controller.dart';
import 'package:smartaid_mobile/features/ems/ems_dashboard_page.dart';
import 'package:smartaid_mobile/features/ems/ems_repository.dart';
import 'package:smartaid_mobile/features/incidents/incidents_controller.dart';

void main() {
  const testSession = Session(
    email: 'demo.ems@smartaid.local',
    displayName: 'Demo EMS Dispatcher',
    roles: ['EMS'],
    accessToken: 'test-access',
    refreshToken: 'test-refresh',
  );

  group('Multi-Responder Model & Serialization', () {
    test('EmergencyResponder serializes and deserializes correctly', () {
      const responder = EmergencyResponder(
        volunteerId: 'VOL-101',
        volunteerName: 'Dr. Tariq Ziad',
        taskType: 'PRIMARY_RESPONSE',
        responseStatus: 'ACCEPTED',
        etaMinutes: 3,
      );

      final json = responder.toJson();
      expect(json['volunteerId'], 'VOL-101');
      expect(json['volunteerName'], 'Dr. Tariq Ziad');
      expect(json['taskType'], 'PRIMARY_RESPONSE');
      expect(json['responseStatus'], 'ACCEPTED');
      expect(json['etaMinutes'], 3);

      final restored = EmergencyResponder.fromJson(json);
      expect(restored.volunteerId, 'VOL-101');
      expect(restored.volunteerName, 'Dr. Tariq Ziad');
      expect(restored.taskType, 'PRIMARY_RESPONSE');
      expect(restored.responseStatus, 'ACCEPTED');
      expect(restored.etaMinutes, 3);
    });

    test('EmergencyIncidentDetail correctly parses list of assigned responders', () {
      final json = {
        'incident': {
          'id': 'INC-MR-001',
          'emergencyType': 'CARDIAC',
          'status': 'RESPONDER_ASSIGNED',
          'priority': 'CRITICAL',
          'location': {'latitude': 30.0444, 'longitude': 31.2357},
          'createdAt': DateTime.now().toIso8601String(),
        },
        'timeline': [
          {
            'status': 'SEARCHING',
            'reason': 'Looking for nearby responders',
            'occurredAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          },
        ],
        'responders': [
          {
            'volunteerId': 'VOL-001',
            'volunteerName': 'Ahmed Hassan',
            'taskType': 'PRIMARY_RESPONSE',
            'responseStatus': 'ACCEPTED',
            'etaMinutes': 4,
          },
          {
            'volunteerId': 'VOL-002',
            'volunteerName': 'Sarah Mansour',
            'taskType': 'TRIAGE_CPR_SUPPORT',
            'responseStatus': 'ACCEPTED',
            'etaMinutes': 6,
          },
          {
            'volunteerId': 'VOL-003',
            'volunteerName': 'Mahmoud Ali',
            'taskType': 'AED_CROWD_CONTROL',
            'responseStatus': 'ACCEPTED',
            'etaMinutes': 7,
          },
        ],
      };

      final detail = EmergencyIncidentDetail.fromJson(json);
      expect(detail.incident.id, 'INC-MR-001');
      expect(detail.responders.length, 3);
      expect(detail.responders[0].volunteerName, 'Ahmed Hassan');
      expect(detail.responders[0].taskType, 'PRIMARY_RESPONSE');
      expect(detail.responders[1].volunteerName, 'Sarah Mansour');
      expect(detail.responders[1].taskType, 'TRIAGE_CPR_SUPPORT');
      expect(detail.responders[2].volunteerName, 'Mahmoud Ali');
      expect(detail.responders[2].taskType, 'AED_CROWD_CONTROL');
    });
  });

  group('Multi-Responder UI Rendering', () {
    testWidgets('ActiveEmergencyPage renders Assigned Emergency Responders card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final incident = EmergencyIncident(
        id: 'INC-UI-01',
        emergencyType: 'CARDIAC',
        status: 'RESPONDER_ASSIGNED',
        priority: 'CRITICAL',
        latitude: 30.0444,
        longitude: 31.2357,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final detail = EmergencyIncidentDetail(
        incident: incident,
        timeline: [
          IncidentTimelineEvent(
            status: 'SEARCHING',
            reason: 'Searching for nearby responders',
            occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ],
        responders: const [
          EmergencyResponder(
            volunteerId: 'VOL-001',
            volunteerName: 'Ahmed Hassan',
            taskType: 'PRIMARY_RESPONSE',
            responseStatus: 'ACCEPTED',
            etaMinutes: 4,
          ),
          EmergencyResponder(
            volunteerId: 'VOL-002',
            volunteerName: 'Sarah Mansour',
            taskType: 'TRIAGE_CPR_SUPPORT',
            responseStatus: 'ACCEPTED',
            etaMinutes: 6,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incidentDetailProvider('INC-UI-01').overrideWith(
              (ref) => Future.value(detail),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: ActiveEmergencyPage(incident: incident),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Assigned Emergency Responders'), findsOneWidget);
      expect(find.text('Ahmed Hassan'), findsOneWidget);
      expect(find.text('Primary Response'), findsOneWidget);
      expect(find.text('Sarah Mansour'), findsOneWidget);
      expect(find.text('CPR & Triage Support'), findsOneWidget);
      expect(find.text('4m'), findsOneWidget);
      expect(find.text('6m'), findsOneWidget);
    });

    testWidgets('EmsDashboardPage opens multi-responder dispatch sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockDashboard = EmsDashboard(
        activeIncidents: 1,
        criticalIncidents: 1,
        incidents: const [
          EmsIncident(
            id: 'INC-EMS-01',
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
          child: MaterialApp(
            theme: AppTheme.build(),
            locale: const Locale('en'),
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

      // Find the multi-responder dispatch button
      final multiDispatchFinder = find.widgetWithText(OutlinedButton, 'Multi-Responder Dispatch');
      expect(multiDispatchFinder, findsOneWidget);

      // Tap to open dispatch sheet
      await tester.tap(multiDispatchFinder);
      await tester.pumpAndSettle();

      // Verify the sheet opened with responder options
      expect(find.text('Assign Responders'), findsOneWidget);
      expect(find.text('Ahmed Hassan'), findsOneWidget);
      expect(find.text('Sarah Mansour'), findsOneWidget);
      expect(find.text('Mahmoud Ali'), findsOneWidget);
      expect(find.text('Primary Response'), findsOneWidget);
      expect(find.text('CPR & Triage Support'), findsOneWidget);
      expect(find.text('AED & Crowd Control'), findsOneWidget);
    });
  });
}
