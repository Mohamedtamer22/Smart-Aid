import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class DashboardOverview {
  const DashboardOverview({
    required this.totalIncidents,
    required this.activeIncidents,
    required this.resolvedIncidents,
    required this.averageResponseTimeMinutes,
    required this.volunteerAcceptanceRatePercent,
    required this.incidentsByType,
    required this.incidentsByPriority,
    required this.totalHospitals,
    required this.totalAeds,
    required this.availableAmbulances,
  });

  final int totalIncidents;
  final int activeIncidents;
  final int resolvedIncidents;
  final double averageResponseTimeMinutes;
  final double volunteerAcceptanceRatePercent;
  final Map<String, int> incidentsByType;
  final Map<String, int> incidentsByPriority;
  final int totalHospitals;
  final int totalAeds;
  final int availableAmbulances;

  factory DashboardOverview.fromJson(Map<String, dynamic> json) =>
      DashboardOverview(
        totalIncidents: json['totalIncidents'] as int? ?? 0,
        activeIncidents: json['activeIncidents'] as int? ?? 0,
        resolvedIncidents: json['resolvedIncidents'] as int? ?? 0,
        averageResponseTimeMinutes:
            (json['averageResponseTimeMinutes'] as num?)?.toDouble() ?? 0.0,
        volunteerAcceptanceRatePercent:
            (json['volunteerAcceptanceRatePercent'] as num?)?.toDouble() ?? 0.0,
        incidentsByType:
            (json['incidentsByType'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as int),
            ) ??
            {},
        incidentsByPriority:
            (json['incidentsByPriority'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as int),
            ) ??
            {},
        totalHospitals: json['totalHospitals'] as int? ?? 0,
        totalAeds: json['totalAeds'] as int? ?? 0,
        availableAmbulances: json['availableAmbulances'] as int? ?? 0,
      );
}

class StrategyEvaluation {
  const StrategyEvaluation({
    required this.strategyName,
    required this.hospitalName,
    required this.travelTimeEtaMinutes,
    required this.hasSpecialty,
    required this.hasResource,
    required this.congestionLevel,
    required this.compositeScore,
    required this.explanation,
  });

  final String strategyName;
  final String hospitalName;
  final int travelTimeEtaMinutes;
  final bool hasSpecialty;
  final bool hasResource;
  final int congestionLevel;
  final double compositeScore;
  final String explanation;

  factory StrategyEvaluation.fromJson(Map<String, dynamic> json) =>
      StrategyEvaluation(
        strategyName: json['strategyName'] as String,
        hospitalName: json['hospitalName'] as String,
        travelTimeEtaMinutes: json['travelTimeEtaMinutes'] as int? ?? 0,
        hasSpecialty: json['hasSpecialty'] as bool? ?? false,
        hasResource: json['hasResource'] as bool? ?? false,
        congestionLevel: json['congestionLevel'] as int? ?? 0,
        compositeScore: (json['compositeScore'] as num).toDouble(),
        explanation: json['explanation'] as String? ?? '',
      );
}

class ResearchComparison {
  const ResearchComparison({
    required this.incidentId,
    required this.emergencyType,
    required this.nearestHospital,
    required this.randomHospital,
    required this.smartErRecommendation,
    required this.conclusion,
  });

  final String incidentId;
  final String emergencyType;
  final StrategyEvaluation nearestHospital;
  final StrategyEvaluation randomHospital;
  final StrategyEvaluation smartErRecommendation;
  final String conclusion;

  factory ResearchComparison.fromJson(Map<String, dynamic> json) =>
      ResearchComparison(
        incidentId: json['incidentId'] as String,
        emergencyType: json['emergencyType'] as String,
        nearestHospital: StrategyEvaluation.fromJson(
          json['nearestHospital'] as Map<String, dynamic>,
        ),
        randomHospital: StrategyEvaluation.fromJson(
          json['randomHospital'] as Map<String, dynamic>,
        ),
        smartErRecommendation: StrategyEvaluation.fromJson(
          json['smartErRecommendation'] as Map<String, dynamic>,
        ),
        conclusion: json['conclusion'] as String? ?? '',
      );
}

class ResearchReport {
  const ResearchReport({
    required this.benchmarks,
    required this.nearestAverageScore,
    required this.randomAverageScore,
    required this.smartErAverageScore,
    required this.summaryNotes,
  });

  final List<ResearchComparison> benchmarks;
  final double nearestAverageScore;
  final double randomAverageScore;
  final double smartErAverageScore;
  final String summaryNotes;

  factory ResearchReport.fromJson(Map<String, dynamic> json) => ResearchReport(
    benchmarks: (json['benchmarks'] as List<dynamic>)
        .map((e) => ResearchComparison.fromJson(e as Map<String, dynamic>))
        .toList(),
    nearestAverageScore: (json['nearestAverageScore'] as num).toDouble(),
    randomAverageScore: (json['randomAverageScore'] as num).toDouble(),
    smartErAverageScore: (json['smartErAverageScore'] as num).toDouble(),
    summaryNotes: json['summaryNotes'] as String? ?? '',
  );
}

class AnalyticsRepository {
  AnalyticsRepository(this._api);
  final ApiClient _api;

  static const _demoDashboard = DashboardOverview(
    totalIncidents: 128,
    activeIncidents: 4,
    resolvedIncidents: 124,
    averageResponseTimeMinutes: 6.8,
    volunteerAcceptanceRatePercent: 88.5,
    incidentsByType: {
      'CARDIAC': 34,
      'TRAUMA': 48,
      'ACCIDENT': 26,
      'MEDICAL': 20,
    },
    incidentsByPriority: {
      'CRITICAL': 22,
      'HIGH': 54,
      'MEDIUM': 42,
      'LOW': 10,
    },
    totalHospitals: 8,
    totalAeds: 24,
    availableAmbulances: 9,
  );

  static const _demoResearchReport = ResearchReport(
    benchmarks: [
      ResearchComparison(
        incidentId: 'INC-DEMO-01',
        emergencyType: 'CARDIAC',
        nearestHospital: StrategyEvaluation(
          strategyName: 'Nearest Only',
          hospitalName: 'Local Clinic',
          travelTimeEtaMinutes: 4,
          hasSpecialty: false,
          hasResource: false,
          congestionLevel: 1,
          compositeScore: 42.0,
          explanation: 'Nearest but lacks cardiac catheterization lab.',
        ),
        randomHospital: StrategyEvaluation(
          strategyName: 'Random Destination',
          hospitalName: 'General Hospital',
          travelTimeEtaMinutes: 18,
          hasSpecialty: true,
          hasResource: false,
          congestionLevel: 3,
          compositeScore: 35.0,
          explanation: 'Long delay and high ER congestion.',
        ),
        smartErRecommendation: StrategyEvaluation(
          strategyName: 'Smart ER Routing (AI)',
          hospitalName: 'Cairo Emergency Hospital (قصر العيني للطوارئ)',
          travelTimeEtaMinutes: 7,
          hasSpecialty: true,
          hasResource: true,
          congestionLevel: 1,
          compositeScore: 94.5,
          explanation: 'Optimal match: dedicated cardiac ICU bed with immediate availability.',
        ),
        conclusion: 'Smart ER routing saved an estimated 11 minutes in critical door-to-balloon time.',
      ),
    ],
    nearestAverageScore: 45.2,
    randomAverageScore: 38.0,
    smartErAverageScore: 92.4,
    summaryNotes: 'Smart ER algorithm achieved 47.2% improvement in critical clinical survival scores over naive nearest routing.',
  );

  Future<DashboardOverview> getDashboard() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/analytics/dashboard',
      );
      if (response.data == null) return _demoDashboard;
      return DashboardOverview.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoDashboard;
      }
      throw failure;
    }
  }

  Future<ResearchReport> runComparison() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/analytics/research/smart-er-comparison',
      );
      if (response.data == null) return _demoResearchReport;
      return ResearchReport.fromJson(response.data!);
    } on DioException catch (error) {
      final failure = ApiFailure.fromDio(error);
      if (failure.isNetworkError) {
        return _demoResearchReport;
      }
      throw failure;
    }
  }
}
