import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class EmsIncident {
  const EmsIncident({
    required this.id,
    required this.emergencyType,
    required this.status,
    required this.priority,
  });
  final String id;
  final String emergencyType;
  final String status;
  final String priority;

  factory EmsIncident.fromJson(Map<String, dynamic> json) => EmsIncident(
    id: json['id'] as String,
    emergencyType: json['emergencyType'] as String,
    status: json['status'] as String,
    priority: json['priority'] as String,
  );
}

class EmsDashboard {
  const EmsDashboard({
    required this.activeIncidents,
    required this.criticalIncidents,
    required this.incidents,
  });
  final int activeIncidents;
  final int criticalIncidents;
  final List<EmsIncident> incidents;

  factory EmsDashboard.fromJson(Map<String, dynamic> json) => EmsDashboard(
    activeIncidents: json['activeIncidents'] as int,
    criticalIncidents: json['criticalIncidents'] as int,
    incidents: (json['incidents'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(EmsIncident.fromJson)
        .toList(),
  );
}

class EmsRepository {
  EmsRepository(this._api);
  final ApiClient _api;

  Future<EmsDashboard> dashboard() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/ems/dashboard',
      );
      return EmsDashboard.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return const EmsDashboard(
          activeIncidents: 2,
          criticalIncidents: 1,
          incidents: [
            EmsIncident(
              id: 'INC-DEMO-01',
              emergencyType: 'CARDIAC_ARREST',
              status: 'DISPATCHED',
              priority: 'CRITICAL',
            ),
            EmsIncident(
              id: 'INC-DEMO-02',
              emergencyType: 'TRAFFIC_COLLISION',
              status: 'REPORTED',
              priority: 'HIGH',
            ),
          ],
        );
      }
      throw failure;
    }
  }

  Future<void> assign(String incidentId) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/api/ems/incidents/$incidentId/assign',
      );
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return; // Silent success in demo fallback
      }
      throw failure;
    }
  }

  Future<void> assignResponders(
    String incidentId,
    List<Map<String, String>> responders,
  ) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/api/ems/incidents/$incidentId/assign-responders',
        data: {'responders': responders},
      );
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return;
      }
      throw failure;
    }
  }
}
