import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/location/location_service.dart';
import '../../core/network/api_client.dart';
import 'emergency_repository.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>(
  (ref) => EmergencyRepository(ref.read(apiClientProvider)),
);
final sosControllerProvider =
    AsyncNotifierProvider<SosController, EmergencyIncident?>(SosController.new);

class SosFailure implements Exception {
  const SosFailure(this.kind);
  final SosFailureKind kind;
}

enum SosFailureKind { permission, location, network }

class SosController extends AsyncNotifier<EmergencyIncident?> {
  String? _pendingIdempotencyKey;

  @override
  FutureOr<EmergencyIncident?> build() => null;
  Future<void> send({EmergencyTriage? triage}) async {
    state = const AsyncLoading();
    try {
      final locationService = ref.read(locationServiceProvider);
      Position? location;
      try {
        location = await locationService.getExactCurrentPosition(
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        location = null;
      }
      location ??= LocationService.fallbackPosition();

      // Keep the key for an uncertain network retry. The server returns the
      // first confirmed incident for the same key instead of dispatching twice.
      final idempotencyKey = _pendingIdempotencyKey ??= _newIdempotencyKey();
      final incident = await ref
          .read(emergencyRepositoryProvider)
          .createManual(
            location.latitude,
            location.longitude,
            triage: triage,
            idempotencyKey: idempotencyKey,
          );
      _pendingIdempotencyKey = null;
      state = AsyncData(incident);
    } on SosFailure catch (failure, stack) {
      state = AsyncError(failure, stack);
    } on ApiFailure catch (failure, stack) {
      state = AsyncError(const SosFailure(SosFailureKind.network), stack);
    } on TimeoutException catch (_, stack) {
      state = AsyncError(const SosFailure(SosFailureKind.network), stack);
    } catch (_, stack) {
      state = AsyncError(const SosFailure(SosFailureKind.network), stack);
    }
  }

  void reset() => state = const AsyncData(null);

  String _newIdempotencyKey() {
    final bytes = List<int>.generate(24, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
