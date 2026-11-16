import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../emergency/emergency_repository.dart';
import '../emergency/sos_controller.dart';

final myIncidentsProvider = FutureProvider.autoDispose<List<EmergencyIncident>>(
  (ref) => ref.read(emergencyRepositoryProvider).mine(),
);
final incidentDetailProvider = FutureProvider.autoDispose
    .family<EmergencyIncidentDetail, String>(
      (ref, id) => ref.read(emergencyRepositoryProvider).detail(id),
    );
