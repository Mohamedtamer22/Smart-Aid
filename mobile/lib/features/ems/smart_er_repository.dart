import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class HospitalRecommendation {
  const HospitalRecommendation({
    required this.hospitalId,
    required this.hospitalName,
    required this.score,
    required this.etaMinutes,
    required this.travelTimeScore,
    required this.capabilityScore,
    required this.specialtyScore,
    required this.congestionScore,
    required this.reasons,
  });
  final String hospitalId;
  final String hospitalName;
  final double score;
  final int etaMinutes;
  final double travelTimeScore;
  final double capabilityScore;
  final double specialtyScore;
  final double congestionScore;
  final List<String> reasons;
  factory HospitalRecommendation.fromJson(Map<String, dynamic> json) =>
      HospitalRecommendation(
        hospitalId: json['hospitalId'] as String,
        hospitalName: json['hospitalName'] as String,
        score: (json['score'] as num).toDouble(),
        etaMinutes: json['etaMinutes'] as int,
        travelTimeScore: (json['travelTimeScore'] as num).toDouble(),
        capabilityScore: (json['capabilityScore'] as num).toDouble(),
        specialtyScore: (json['specialtyScore'] as num).toDouble(),
        congestionScore: (json['congestionScore'] as num).toDouble(),
        reasons: (json['reasons'] as List<dynamic>).cast<String>(),
      );
}

class SmartErRepository {
  SmartErRepository(this._api);
  final ApiClient _api;
  Future<List<HospitalRecommendation>> recommendations(
    String incidentId,
  ) async {
    try {
      final result = await _api.get<List<dynamic>>(
        '/api/smart-er/incidents/$incidentId/recommendations',
      );
      return result.data!
          .cast<Map<String, dynamic>>()
          .map(HospitalRecommendation.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  Future<void> confirmDestination(
    String incidentId,
    String hospitalName,
  ) async {
    try {
      await _api.patch<Map<String, dynamic>>(
        '/api/incidents/$incidentId/status',
        data: {
          'status': 'HOSPITAL_SELECTED',
          'reason': 'Destination confirmed by EMS: $hospitalName',
        },
      );
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
