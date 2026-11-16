import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'volunteer_repository.dart';

final volunteerRepositoryProvider = Provider<VolunteerRepository>(
  (ref) => VolunteerRepository(ref.read(apiClientProvider)),
);
final volunteerDashboardProvider =
    FutureProvider.autoDispose<VolunteerDashboard>(
      (ref) => ref.read(volunteerRepositoryProvider).dashboard(),
    );
final nearbyVolunteerIncidentsProvider =
    FutureProvider.autoDispose<List<VolunteerIncident>>(
      (ref) => ref.read(volunteerRepositoryProvider).nearbyIncidents(),
    );
