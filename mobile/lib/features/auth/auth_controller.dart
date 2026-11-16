import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      AuthRepository(ref.read(apiClientProvider), ref.read(tokenStoreProvider)),
);
final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

class SessionController extends AsyncNotifier<Session?> {
  @override
  FutureOr<Session?> build() => ref.read(authRepositoryProvider).restore();
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .login(email: email, password: password),
    );
  }

  Future<void> register(
    String email,
    String password,
    String displayName,
    RegistrationType accountType, {
    String? organizationName,
    String? registrationNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(
            email: email,
            password: password,
            displayName: displayName,
            accountType: accountType,
            organizationName: organizationName,
            registrationNumber: registrationNumber,
          ),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void clearFailure() => state = const AsyncData(null);
}
