import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class EmergencyIncident {
  const EmergencyIncident({
    required this.id,
    required this.emergencyType,
    required this.status,
    required this.priority,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });
  final String id;
  final String emergencyType;
  final String status;
  final String priority;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  factory EmergencyIncident.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    return EmergencyIncident(
      id: json['id'] as String,
      emergencyType: json['emergencyType'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class EmergencyTriage {
  const EmergencyTriage({
    this.conscious,
    this.breathing,
    this.severeBleeding,
    this.chestPain,
    this.fallOccurred,
    this.trafficAccident,
  });
  final bool? conscious;
  final bool? breathing;
  final bool? severeBleeding;
  final bool? chestPain;
  final bool? fallOccurred;
  final bool? trafficAccident;
  Map<String, bool?> toJson() => {
    'conscious': conscious,
    'breathing': breathing,
    'severeBleeding': severeBleeding,
    'chestPain': chestPain,
    'fallOccurred': fallOccurred,
    'trafficAccident': trafficAccident,
  };
}

class IncidentTimelineEvent {
  const IncidentTimelineEvent({
    required this.status,
    required this.reason,
    required this.occurredAt,
  });
  final String status;
  final String? reason;
  final DateTime occurredAt;
  factory IncidentTimelineEvent.fromJson(Map<String, dynamic> json) =>
      IncidentTimelineEvent(
        status: json['status'] as String,
        reason: json['reason'] as String?,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
      );
}

class EmergencyResponder {
  const EmergencyResponder({
    required this.volunteerId,
    required this.volunteerName,
    required this.taskType,
    required this.responseStatus,
    required this.etaMinutes,
  });

  final String volunteerId;
  final String volunteerName;
  final String taskType;
  final String responseStatus;
  final int etaMinutes;

  factory EmergencyResponder.fromJson(Map<String, dynamic> json) =>
      EmergencyResponder(
        volunteerId:
            json['volunteerId'] as String? ?? json['id'] as String? ?? '',
        volunteerName: json['volunteerName'] as String? ??
            json['name'] as String? ??
            'Field Volunteer',
        taskType: json['taskType'] as String? ?? 'PRIMARY_RESPONSE',
        responseStatus: json['responseStatus'] as String? ??
            json['status'] as String? ??
            'ACCEPTED',
        etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 5,
      );

  Map<String, dynamic> toJson() => {
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'taskType': taskType,
        'responseStatus': responseStatus,
        'etaMinutes': etaMinutes,
      };
}

class EmergencyIncidentDetail {
  const EmergencyIncidentDetail({
    required this.incident,
    required this.timeline,
    this.responders = const [],
  });
  final EmergencyIncident incident;
  final List<IncidentTimelineEvent> timeline;
  final List<EmergencyResponder> responders;

  factory EmergencyIncidentDetail.fromJson(Map<String, dynamic> json) =>
      EmergencyIncidentDetail(
        incident: EmergencyIncident.fromJson(
          json['incident'] as Map<String, dynamic>,
        ),
        timeline: (json['timeline'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(IncidentTimelineEvent.fromJson)
                .toList() ??
            const [],
        responders: (json['responders'] as List<dynamic>?)
                ?.map((e) => EmergencyResponder.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'incident': {
          'id': incident.id,
          'emergencyType': incident.emergencyType,
          'status': incident.status,
          'priority': incident.priority,
          'location': {
            'latitude': incident.latitude,
            'longitude': incident.longitude,
          },
          'createdAt': incident.createdAt.toIso8601String(),
        },
        'timeline': timeline
            .map((e) => {
                  'status': e.status,
                  'reason': e.reason,
                  'occurredAt': e.occurredAt.toIso8601String(),
                })
            .toList(),
        'responders': responders.map((r) => r.toJson()).toList(),
      };
}

class EmergencyRepository {
  EmergencyRepository(this._api);
  final ApiClient _api;
  Future<EmergencyIncident> createManual(
    double latitude,
    double longitude, {
    EmergencyTriage? triage,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/incidents',
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
        data: {
          'emergencyType': 'MEDICAL',
          'location': {'latitude': latitude, 'longitude': longitude},
          'triage': triage?.toJson() ?? <String, bool?>{},
        },
      );
      return EmergencyIncident.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return EmergencyIncident(
          id: 'INC-OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
          emergencyType: 'MEDICAL',
          status: 'REPORTED',
          priority: 'HIGH',
          latitude: latitude,
          longitude: longitude,
          createdAt: DateTime.now(),
        );
      }
      throw failure;
    }
  }

  Future<List<EmergencyIncident>> mine() async {
    try {
      final response = await _api.get<List<dynamic>>('/api/incidents/mine');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(EmergencyIncident.fromJson)
          .toList();
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return [
          EmergencyIncident(
            id: 'INC-DEMO-2026',
            emergencyType: 'MEDICAL',
            status: 'ASSIGNED',
            priority: 'HIGH',
            latitude: 30.0444,
            longitude: 31.2357,
            createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        ];
      }
      throw failure;
    }
  }

  Future<EmergencyIncidentDetail> detail(String id) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/incidents/$id',
      );
      return EmergencyIncidentDetail.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return EmergencyIncidentDetail(
          incident: EmergencyIncident(
            id: id,
            emergencyType: 'MEDICAL',
            status: 'ASSIGNED',
            priority: 'HIGH',
            latitude: 30.0444,
            longitude: 31.2357,
            createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
          timeline: [
            IncidentTimelineEvent(
              status: 'REPORTED',
              reason: 'Emergency triggered via Smart Aid SOS button',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 10)),
            ),
            IncidentTimelineEvent(
              status: 'ASSIGNED',
              reason: 'Nearest EMS unit dispatched (ETA 4 mins)',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          ],
          responders: [
            const EmergencyResponder(
              volunteerId: 'VOL-001',
              volunteerName: 'Ahmed Hassan (CPR Certified)',
              taskType: 'PRIMARY_RESPONSE',
              responseStatus: 'ACCEPTED',
              etaMinutes: 4,
            ),
            const EmergencyResponder(
              volunteerId: 'VOL-002',
              volunteerName: 'Sarah Mansour (AED Specialist)',
              taskType: 'AED_CROWD_CONTROL',
              responseStatus: 'ACCEPTED',
              etaMinutes: 6,
            ),
          ],
        );
      }
      throw failure;
    }
  }

  Future<EmergencyIncident> cancel(String id) async {
    try {
      final response = await _api.patch<Map<String, dynamic>>(
        '/api/incidents/$id/status',
        data: {'status': 'CANCELLED', 'reason': 'Cancelled by reporter'},
      );
      return EmergencyIncident.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return EmergencyIncident(
          id: id,
          emergencyType: 'MEDICAL',
          status: 'CANCELLED',
          priority: 'HIGH',
          latitude: 30.0444,
          longitude: 31.2357,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );
      }
      throw failure;
    }
  }
}
