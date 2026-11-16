import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'ems_repository.dart';

final emsRepositoryProvider = Provider<EmsRepository>(
  (ref) => EmsRepository(ref.read(apiClientProvider)),
);
final emsDashboardProvider = FutureProvider.autoDispose<EmsDashboard>(
  (ref) => ref.read(emsRepositoryProvider).dashboard(),
);
