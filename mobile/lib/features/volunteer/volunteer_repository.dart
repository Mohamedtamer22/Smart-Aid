import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class VolunteerProfile {
  const VolunteerProfile({
    required this.verified,
    required this.available,
    required this.certificationValid,
    required this.dispatchEligible,
    required this.skills,
    this.latitude,
    this.longitude,
  });
  final bool verified;
  final bool available;
  final bool certificationValid;
  final bool dispatchEligible;
  final List<String> skills;
  final double? latitude;
  final double? longitude;

  factory VolunteerProfile.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return VolunteerProfile(
      verified: json['verified'] == true,
      available: json['available'] == true,
      certificationValid: json['certificationValid'] == true,
      dispatchEligible: json['dispatchEligible'] == true,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      latitude: location == null
          ? null
          : (location['latitude'] as num?)?.toDouble(),
      longitude: location == null
          ? null
          : (location['longitude'] as num?)?.toDouble(),
    );
  }
}

class VolunteerIncident {
  const VolunteerIncident({
    required this.id,
    required this.emergencyType,
    required this.priority,
    required this.distanceKm,
    required this.etaMinutes,
    required this.latitude,
    required this.longitude,
    required this.matchingSkills,
  });
  final String id;
  final String emergencyType;
  final String priority;
  final double distanceKm;
  final int etaMinutes;
  final double latitude;
  final double longitude;
  final List<String> matchingSkills;

  factory VolunteerIncident.fromJson(Map<String, dynamic> json) {
    final incident = (json['incident'] as Map<String, dynamic>?) ?? const {};
    final location = (incident['location'] as Map<String, dynamic>?) ?? const {};
    return VolunteerIncident(
      id: (incident['id'] as String?) ?? '',
      emergencyType: (incident['emergencyType'] as String?) ?? '',
      priority: (incident['priority'] as String?) ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: (json['estimatedEtaMinutes'] as num?)?.toInt() ?? 0,
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
      matchingSkills: (json['matchingSkills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class VolunteerMission {
  const VolunteerMission({
    required this.id,
    required this.status,
    required this.etaMinutes,
    required this.incident,
  });
  final String id;
  final String status;
  final int etaMinutes;
  final VolunteerIncident incident;

  factory VolunteerMission.fromJson(Map<String, dynamic> json) {
    final incident = (json['incident'] as Map<String, dynamic>?) ?? const {};
    final location = (incident['location'] as Map<String, dynamic>?) ?? const {};
    final eta = (json['estimatedEtaMinutes'] as num?)?.toInt() ?? 0;
    return VolunteerMission(
      id: (json['id'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      etaMinutes: eta,
      incident: VolunteerIncident(
        id: (incident['id'] as String?) ?? '',
        emergencyType: (incident['emergencyType'] as String?) ?? '',
        priority: (incident['priority'] as String?) ?? '',
        distanceKm: 0,
        etaMinutes: eta,
        latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
        matchingSkills: const [],
      ),
    );
  }
}

class VolunteerDashboard {
  const VolunteerDashboard({
    required this.profile,
    required this.nearbyEligibleIncidents,
    this.activeMission,
  });
  final VolunteerProfile profile;
  final int nearbyEligibleIncidents;
  final VolunteerMission? activeMission;

  factory VolunteerDashboard.fromJson(Map<String, dynamic> json) =>
      VolunteerDashboard(
        profile: VolunteerProfile.fromJson(
          (json['profile'] as Map<String, dynamic>?) ?? const {},
        ),
        nearbyEligibleIncidents:
            (json['nearbyEligibleIncidents'] as num?)?.toInt() ?? 0,
        activeMission: json['activeMission'] == null
            ? null
            : VolunteerMission.fromJson(
                json['activeMission'] as Map<String, dynamic>,
              ),
      );
}

class VolunteerRepository {
  VolunteerRepository(this._api);
  final ApiClient _api;

  static VolunteerProfile _demoProfile = const VolunteerProfile(
    verified: true,
    available: true,
    certificationValid: true,
    dispatchEligible: true,
    skills: ['CPR', 'FIRST_AID', 'AED', 'TRAUMA'],
    latitude: 30.0444,
    longitude: 31.2357,
  );

  static final List<VolunteerIncident> _demoNearbyIncidents = [
    const VolunteerIncident(
      id: 'INC-VOL-01',
      emergencyType: 'CARDIAC',
      priority: 'CRITICAL',
      distanceKm: 0.8,
      etaMinutes: 3,
      latitude: 30.0450,
      longitude: 31.2365,
      matchingSkills: ['CPR', 'AED'],
    ),
    const VolunteerIncident(
      id: 'INC-VOL-02',
      emergencyType: 'TRAUMA',
      priority: 'HIGH',
      distanceKm: 1.4,
      etaMinutes: 5,
      latitude: 30.0410,
      longitude: 31.2310,
      matchingSkills: ['FIRST_AID', 'TRAUMA'],
    ),
    const VolunteerIncident(
      id: 'INC-VOL-03',
      emergencyType: 'MEDICAL',
      priority: 'MEDIUM',
      distanceKm: 2.1,
      etaMinutes: 8,
      latitude: 30.0490,
      longitude: 31.2400,
      matchingSkills: ['FIRST_AID'],
    ),
  ];

  static VolunteerMission? _demoActiveMission;

  static VolunteerDashboard get _demoDashboard => VolunteerDashboard(
    profile: _demoProfile,
    nearbyEligibleIncidents: _demoNearbyIncidents.length,
    activeMission: _demoActiveMission,
  );

  Future<VolunteerDashboard> dashboard() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/volunteers/dashboard',
      );
      if (response.data == null) return _demoDashboard;
      return VolunteerDashboard.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoDashboard;
      }
      throw failure;
    }
  }

  Future<VolunteerProfile> startOnboarding() async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/volunteers/me/onboarding',
      );
      if (response.data == null) return _demoProfile;
      return VolunteerProfile.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoProfile;
      }
      throw failure;
    }
  }

  Future<VolunteerProfile> updateAvailability(bool available) async {
    try {
      final updated = await _profilePut(
        '/api/volunteers/me/availability',
        {'available': available},
      );
      _demoProfile = updated;
      return updated;
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        _demoProfile = VolunteerProfile(
          verified: _demoProfile.verified,
          available: available,
          certificationValid: _demoProfile.certificationValid,
          dispatchEligible: _demoProfile.dispatchEligible,
          skills: _demoProfile.skills,
          latitude: _demoProfile.latitude,
          longitude: _demoProfile.longitude,
        );
        return _demoProfile;
      }
      throw failure;
    }
  }

  Future<VolunteerProfile> updateLocation(double latitude, double longitude) async {
    try {
      final updated = await _profilePut('/api/volunteers/me/location', {
        'latitude': latitude,
        'longitude': longitude,
      });
      _demoProfile = updated;
      return updated;
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        _demoProfile = VolunteerProfile(
          verified: _demoProfile.verified,
          available: _demoProfile.available,
          certificationValid: _demoProfile.certificationValid,
          dispatchEligible: _demoProfile.dispatchEligible,
          skills: _demoProfile.skills,
          latitude: latitude,
          longitude: longitude,
        );
        return _demoProfile;
      }
      throw failure;
    }
  }

  Future<List<VolunteerIncident>> nearbyIncidents() async {
    try {
      final response = await _api.get<List<dynamic>>(
        '/api/volunteers/incidents/nearby',
      );
      if (response.data == null) return const [];
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(VolunteerIncident.fromJson)
          .toList();
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoNearbyIncidents;
      }
      throw failure;
    }
  }

  Future<VolunteerMission> accept(String incidentId) async {
    try {
      final res = await _missionPost(
        '/api/volunteers/incidents/$incidentId/accept',
      );
      _demoActiveMission = res;
      return res;
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        final matching = _demoNearbyIncidents.firstWhere(
          (inc) => inc.id == incidentId,
          orElse: () => _demoNearbyIncidents.first,
        );
        _demoActiveMission = VolunteerMission(
          id: 'MISS-${DateTime.now().millisecondsSinceEpoch}',
          status: 'ACCEPTED',
          etaMinutes: matching.etaMinutes,
          incident: matching,
        );
        return _demoActiveMission!;
      }
      throw failure;
    }
  }

  Future<VolunteerMission> updateMission(String missionId, String status) async {
    try {
      final res = await _missionPatch(
        '/api/volunteers/missions/$missionId',
        {'status': status},
      );
      if (status == 'COMPLETED' || status == 'CANCELLED') {
        _demoActiveMission = null;
      } else {
        _demoActiveMission = res;
      }
      return res;
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        if (_demoActiveMission != null) {
          if (status == 'COMPLETED' || status == 'CANCELLED') {
            final completed = VolunteerMission(
              id: _demoActiveMission!.id,
              status: status,
              etaMinutes: 0,
              incident: _demoActiveMission!.incident,
            );
            _demoActiveMission = null;
            return completed;
          } else {
            _demoActiveMission = VolunteerMission(
              id: _demoActiveMission!.id,
              status: status,
              etaMinutes: _demoActiveMission!.etaMinutes,
              incident: _demoActiveMission!.incident,
            );
            return _demoActiveMission!;
          }
        }
      }
      throw failure;
    }
  }

  Future<VolunteerProfile> _profilePut(String path, Object data) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(path, data: data);
      return VolunteerProfile.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  Future<VolunteerMission> _missionPost(String path) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(path);
      return VolunteerMission.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  Future<VolunteerMission> _missionPatch(String path, Object data) async {
    try {
      final response = await _api.patch<Map<String, dynamic>>(path, data: data);
      return VolunteerMission.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
