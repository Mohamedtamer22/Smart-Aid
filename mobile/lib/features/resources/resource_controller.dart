import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'resource_repository.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>(
  (ref) => ResourceRepository(ref.read(apiClientProvider)),
);

class VerifiedHospitalsNotifier extends AsyncNotifier<List<HospitalResource>> {
  @override
  Future<List<HospitalResource>> build() async {
    final repo = ref.read(resourceRepositoryProvider);
    _refreshSilently(repo);
    return repo.cachedOrFallbackHospitals();
  }

  void _refreshSilently(ResourceRepository repo) {
    repo
        .verifiedHospitals()
        .then((data) {
          state = AsyncData(data);
        })
        .catchError((_) {});
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(resourceRepositoryProvider).verifiedHospitals(),
    );
  }
}

final verifiedHospitalsProvider =
    AsyncNotifierProvider<VerifiedHospitalsNotifier, List<HospitalResource>>(
      VerifiedHospitalsNotifier.new,
    );

class VerifiedAedsNotifier extends AsyncNotifier<List<AedResource>> {
  @override
  Future<List<AedResource>> build() async {
    final repo = ref.read(resourceRepositoryProvider);
    _refreshSilently(repo);
    return repo.cachedOrFallbackAeds();
  }

  void _refreshSilently(ResourceRepository repo) {
    repo
        .verifiedAeds()
        .then((data) {
          state = AsyncData(data);
        })
        .catchError((_) {});
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(resourceRepositoryProvider).verifiedAeds(),
    );
  }
}

final verifiedAedsProvider =
    AsyncNotifierProvider<VerifiedAedsNotifier, List<AedResource>>(
      VerifiedAedsNotifier.new,
    );

class AmbulancesNotifier extends AsyncNotifier<List<AmbulanceResource>> {
  @override
  Future<List<AmbulanceResource>> build() async {
    final repo = ref.read(resourceRepositoryProvider);
    _refreshSilently(repo);
    return repo.cachedOrFallbackAmbulances();
  }

  void _refreshSilently(ResourceRepository repo) {
    repo
        .ambulances()
        .then((data) {
          state = AsyncData(data);
        })
        .catchError((_) {});
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(resourceRepositoryProvider).ambulances(),
    );
  }
}

final ambulancesProvider =
    AsyncNotifierProvider<AmbulancesNotifier, List<AmbulanceResource>>(
      AmbulancesNotifier.new,
    );
