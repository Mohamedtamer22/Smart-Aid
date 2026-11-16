import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.read(apiClientProvider)),
);

final analyticsDashboardProvider = FutureProvider<DashboardOverview>(
  (ref) => ref.read(analyticsRepositoryProvider).getDashboard(),
);

final researchReportProvider = FutureProvider<ResearchReport>(
  (ref) => ref.read(analyticsRepositoryProvider).runComparison(),
);
