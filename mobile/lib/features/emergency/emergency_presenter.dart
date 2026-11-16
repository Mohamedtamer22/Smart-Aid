import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

String emergencyTypeLabel(AppLocalizations l, String type) => switch (type) {
  'CARDIAC' => l.text('emergencyCardiac'),
  'TRAUMA' => l.text('emergencyTrauma'),
  'ACCIDENT' => l.text('emergencyAccident'),
  'MEDICAL' => l.text('emergencyMedical'),
  _ => l.text('emergencyOther'),
};
String incidentStatusLabel(AppLocalizations l, String status) =>
    switch (status) {
      'NEW' => l.text('created'),
      'SEARCHING' => l.text('statusSearching'),
      'RESPONDER_ASSIGNED' => l.text('statusResponderAssigned'),
      'EMS_ASSIGNED' => l.text('statusEmsAssigned'),
      'AMBULANCE_ASSIGNED' => l.text('statusAmbulanceAssigned'),
      'IN_TRANSIT' => l.text('statusInTransit'),
      'HOSPITAL_SELECTED' => l.text('statusHospitalSelected'),
      'AT_HOSPITAL' => l.text('statusAtHospital'),
      'RESOLVED' => l.text('statusCompleted'),
      'CANCELLED' => l.text('statusCancelled'),
      _ => l.text('unknown'),
    };
String priorityLabel(AppLocalizations l, String priority) => switch (priority) {
  'CRITICAL' => l.text('priorityCritical'),
  'HIGH' => l.text('priorityHigh'),
  'STANDARD' => l.text('priorityStandard'),
  'LOW' => l.text('priorityLow'),
  _ => l.text('unknown'),
};
Color priorityColor(String priority) => switch (priority) {
  'CRITICAL' => AppTheme.emergencyRed,
  'HIGH' => const Color(0xffF79009),
  _ => AppTheme.blue,
};
