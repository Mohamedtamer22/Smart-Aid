import '../../core/network/api_client.dart';

class DisasterStatus {
  const DisasterStatus({
    required this.active,
    this.disasterType,
    this.disasterLevel,
    this.affectedArea,
    this.activatedAt,
    required this.activeIncidentsCount,
    required this.respondersMobilizedCount,
  });

  final bool active;
  final String? disasterType;
  final String? disasterLevel;
  final String? affectedArea;
  final DateTime? activatedAt;
  final int activeIncidentsCount;
  final int respondersMobilizedCount;

  factory DisasterStatus.fromJson(Map<String, dynamic> json) => DisasterStatus(
    active: json['active'] as bool? ?? false,
    disasterType: json['disasterType'] as String?,
    disasterLevel: json['disasterLevel'] as String?,
    affectedArea: json['affectedArea'] as String?,
    activatedAt: json['activatedAt'] == null
        ? null
        : DateTime.parse(json['activatedAt'] as String),
    activeIncidentsCount: json['activeIncidentsCount'] as int? ?? 0,
    respondersMobilizedCount: json['respondersMobilizedCount'] as int? ?? 0,
  );
}

class MassCasualtyIncident {
  const MassCasualtyIncident({
    required this.id,
    required this.emergencyType,
    required this.status,
    required this.priority,
    required this.triageTag,
    required this.latitude,
    required this.longitude,
    required this.notes,
    required this.createdAt,
    required this.assignedRespondersCount,
  });

  final String id;
  final String emergencyType;
  final String status;
  final String priority;
  final String triageTag;
  final double latitude;
  final double longitude;
  final String notes;
  final DateTime createdAt;
  final int assignedRespondersCount;

  factory MassCasualtyIncident.fromJson(Map<String, dynamic> json) =>
      MassCasualtyIncident(
        id: json['id'] as String,
        emergencyType: json['emergencyType'] as String? ?? 'UNKNOWN',
        status: json['status'] as String? ?? 'NEW',
        priority: json['priority'] as String? ?? 'STANDARD',
        triageTag: json['triageTag'] as String? ?? 'YELLOW',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        assignedRespondersCount: json['assignedRespondersCount'] as int? ?? 0,
      );
}

class DisasterOverview {
  const DisasterOverview({
    required this.status,
    required this.priorityQueue,
    required this.redCount,
    required this.yellowCount,
    required this.greenCount,
    required this.blackCount,
  });

  final DisasterStatus status;
  final List<MassCasualtyIncident> priorityQueue;
  final int redCount;
  final int yellowCount;
  final int greenCount;
  final int blackCount;

  factory DisasterOverview.fromJson(Map<String, dynamic> json) =>
      DisasterOverview(
        status: DisasterStatus.fromJson(json['status'] as Map<String, dynamic>),
        priorityQueue: (json['priorityQueue'] as List<dynamic>)
            .map(
              (e) => MassCasualtyIncident.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        redCount: json['redCount'] as int? ?? 0,
        yellowCount: json['yellowCount'] as int? ?? 0,
        greenCount: json['greenCount'] as int? ?? 0,
        blackCount: json['blackCount'] as int? ?? 0,
      );
}

class DisasterRepository {
  DisasterRepository(this._api);
  final ApiClient _api;

  static DisasterStatus _demoStatus = DisasterStatus(
    active: true,
    disasterType: 'EARTHQUAKE',
    disasterLevel: 'LEVEL_2',
    affectedArea: 'Cairo Central / وسط القاهرة',
    activatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    activeIncidentsCount: 4,
    respondersMobilizedCount: 18,
  );

  static final List<MassCasualtyIncident> _demoQueue = [
    MassCasualtyIncident(
      id: 'MCI-001',
      emergencyType: 'TRAUMA',
      status: 'ASSIGNED',
      priority: 'CRITICAL',
      triageTag: 'RED',
      latitude: 30.0444,
      longitude: 31.2357,
      notes: 'Severe blunt chest trauma / إصابة صدرية حادة',
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      assignedRespondersCount: 2,
    ),
    MassCasualtyIncident(
      id: 'MCI-002',
      emergencyType: 'FRACTURE',
      status: 'NEW',
      priority: 'HIGH',
      triageTag: 'YELLOW',
      latitude: 30.0460,
      longitude: 31.2380,
      notes: 'Closed femoral fracture / كسر مغلق بالفخذ',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      assignedRespondersCount: 1,
    ),
    MassCasualtyIncident(
      id: 'MCI-003',
      emergencyType: 'LACERATION',
      status: 'REPORTED',
      priority: 'MEDIUM',
      triageTag: 'GREEN',
      latitude: 30.0430,
      longitude: 31.2340,
      notes: 'Superficial cuts, walking / جروح سطحية',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      assignedRespondersCount: 0,
    ),
  ];

  static DisasterOverview get _demoOverview => DisasterOverview(
    status: _demoStatus,
    priorityQueue: _demoQueue,
    redCount: 1,
    yellowCount: 1,
    greenCount: 1,
    blackCount: 0,
  );

  Future<DisasterStatus> getStatus() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/disaster/status',
      );
      if (response.data == null) return _demoStatus;
      return DisasterStatus.fromJson(response.data!);
    } catch (_) {
      return _demoStatus;
    }
  }

  Future<DisasterOverview> getOverview() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/disaster/overview',
      );
      if (response.data == null) return _demoOverview;
      return DisasterOverview.fromJson(response.data!);
    } catch (_) {
      return _demoOverview;
    }
  }

  Future<DisasterStatus> activate({
    required String disasterType,
    required String disasterLevel,
    required String affectedArea,
    String? notes,
  }) async {
    _demoStatus = DisasterStatus(
      active: true,
      disasterType: disasterType,
      disasterLevel: disasterLevel,
      affectedArea: affectedArea,
      activatedAt: DateTime.now(),
      activeIncidentsCount: 4,
      respondersMobilizedCount: 12,
    );
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/disaster/activate',
        data: {
          'disasterType': disasterType,
          'disasterLevel': disasterLevel,
          'affectedArea': affectedArea,
          'notes': notes,
        },
      );
      return DisasterStatus.fromJson(response.data!);
    } catch (_) {
      return _demoStatus;
    }
  }

  Future<DisasterStatus> deactivate() async {
    _demoStatus = const DisasterStatus(
      active: false,
      activeIncidentsCount: 0,
      respondersMobilizedCount: 0,
    );
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/disaster/deactivate',
      );
      return DisasterStatus.fromJson(response.data!);
    } catch (_) {
      return _demoStatus;
    }
  }

  Future<void> updateTriageTag(
    String incidentId,
    String triageTag, {
    String? notes,
  }) async {
    try {
      await _api.patch<dynamic>(
        '/api/disaster/incidents/$incidentId/triage',
        data: {'triageTag': triageTag, 'notes': notes},
      );
    } catch (_) {
      final index = _demoQueue.indexWhere((i) => i.id == incidentId);
      if (index >= 0) {
        final old = _demoQueue[index];
        _demoQueue[index] = MassCasualtyIncident(
          id: old.id,
          emergencyType: old.emergencyType,
          status: old.status,
          priority: old.priority,
          triageTag: triageTag,
          latitude: old.latitude,
          longitude: old.longitude,
          notes: notes ?? old.notes,
          createdAt: old.createdAt,
          assignedRespondersCount: old.assignedRespondersCount,
        );
      }
    }
  }
}
