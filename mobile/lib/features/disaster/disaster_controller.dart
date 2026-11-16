import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'disaster_repository.dart';

final disasterRepositoryProvider = Provider<DisasterRepository>(
  (ref) => DisasterRepository(ref.read(apiClientProvider)),
);

final disasterOverviewProvider = FutureProvider<DisasterOverview>(
  (ref) => ref.read(disasterRepositoryProvider).getOverview(),
);

final disasterStatusProvider = FutureProvider<DisasterStatus>(
  (ref) => ref.read(disasterRepositoryProvider).getStatus(),
);
