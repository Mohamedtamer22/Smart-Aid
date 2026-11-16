import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.read(apiClientProvider)),
);

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final repo = ref.read(notificationsRepositoryProvider);
    _syncSilently(repo);
    return repo.cachedOrFallbackNotifications();
  }

  void _syncSilently(NotificationsRepository repo) {
    repo
        .all()
        .then((fresh) {
          state = AsyncData(fresh);
        })
        .catchError((_) {});
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).all(),
    );
  }

  Future<void> markRead(String id) async {
    final current = state.value;
    if (current != null) {
      state = AsyncData([
        for (final item in current)
          if (item.id == id)
            AppNotification(
              id: item.id,
              type: item.type,
              read: true,
              createdAt: item.createdAt,
            )
          else
            item,
      ]);
    }
    try {
      await ref.read(notificationsRepositoryProvider).markRead(id);
    } catch (_) {
      // Silent catch or background sync
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );
