import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'smart_er_repository.dart';

final smartErRepositoryProvider = Provider<SmartErRepository>(
  (ref) => SmartErRepository(ref.read(apiClientProvider)),
);
final smartErRecommendationsProvider = FutureProvider.autoDispose
    .family<List<HospitalRecommendation>, String>(
      (ref, incidentId) =>
          ref.read(smartErRepositoryProvider).recommendations(incidentId),
    );
